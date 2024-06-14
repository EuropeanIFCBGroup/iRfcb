import os
import pandas as pd
import numpy as np
import re
from matplotlib import pyplot as plt
from math import floor, log10
from scipy.optimize import curve_fit
import datetime as dt
import json
import operator
from types import SimpleNamespace


class Target:
    micron_factor = 1 / 2.7

    def __init__(self, sample, i, fea_file):
        self.sample = sample
        self.index = i
        self.biovolume = fea_file['Biovolume'][i] * pow(Target.micron_factor, 3)
        self.equiv_diameter = fea_file['EquivDiameter'][i] * Target.micron_factor
        self.major_axis_length = fea_file['MajorAxisLength'][i] * Target.micron_factor
        self.minor_axis_length = fea_file['MinorAxisLength'][i] * Target.micron_factor
        self.json = {
            "index": i,
            "biovolume": self.biovolume,
            "equiv_diameter": self.equiv_diameter,
            "major_axis_length": self.major_axis_length,
            "minor_axis_length": self.minor_axis_length
        }


class Sample:

    def __init__(self, name, feature_dir, roi_dir, overall_bin, ifcb):
        self.name = name
        self.ifcb = ifcb
        self.micron_factor = 1 / 2.7
        self.summary = {}
        self.data = []
        self.psd = {}
        self.coeffs = {}
        self.r_squared = {}
        self.max_diff = 0
        self.bin = overall_bin

        def getMATLabDate():
            datetime = dt.datetime.strptime(self.name, 'D%Y%m%dT%H%M%S')
            delta = (datetime - dt.datetime(1, 1, 1))
            datenum = delta.total_seconds() / (24 * 60 * 60) + 367
            return datenum

        self.datenum = getMATLabDate()

        print(f'Processing {name}')

        self.features = pd.read_csv(f'{feature_dir}/{name}_{ifcb}_fea_v2.csv')
        self.metadata = self.read_metadata(roi_dir, name)
        self.targets = [Target(self, i, self.features) for i in range(len(self.features.Biovolume))]
        self.mL_analyzed = self.get_volume()
        self.capture_percent = self.get_capture_percent(roi_dir, name)
        self.humidity = float(self.metadata['humidity'][0])
        self.bead_run = self.metadata.get('runType', ['NORMAL'])[0] == 'BEADS'

        self.grouped_equiv_diameter = {}
        self.grouped_major_axis_length = {}
        self.grouped_minor_axis_length = {}

        self.grouped_equiv_diameter_export = []
        self.grouped_major_axis_length_export = []
        self.grouped_minor_axis_length_export = []

        self.grouped_equiv_diameter_json = []
        self.grouped_major_axis_length_json = []
        self.grouped_minor_axis_length_json = []

    def to_JSON(self):
        return {
            "name": self.name,
            "ifcb": self.ifcb,
            "micron_factor": self.micron_factor,
            "summary": self.summary,
            "data": self.data,
            "psd": self.psd,
            "coeffs": self.coeffs,
            "r_squared": self.r_squared,
            "max_diff": self.max_diff,
            "bin": {},
            "datenum": self.datenum,
            "features": {},
            "metadata": {},
            "targets": [t.json for t in self.targets],
            "mL_analyzed": self.mL_analyzed,
            "grouped_equiv_diameter": self.grouped_equiv_diameter_json,
            "grouped_major_axis": self.grouped_major_axis_length_json,
            "grouped_minor_axis": self.grouped_minor_axis_length_json,
        }

    def read_metadata(self, roi_dir, name):
        '''Extracts metadata from header file'''

        metadata = {}
        with open(f'{roi_dir}/{name[:9]}/{name}_{self.ifcb}.hdr', 'r') as hdr:
            raw_metadata = [line.strip() for line in hdr.readlines()]
            for line in raw_metadata:
                split = line.split(': ')
                if len(split) < 2:
                    continue
                try:
                    metadata[split[0]] = [float(v) for v in split[1].split(',')]
                except:
                    metadata[split[0]] = split[1].split(',')

        return metadata

    def get_volume(self):
        '''Determines the volume analyzed in the sample in mL'''

        flow_rate = 0.25
        looktime = self.metadata['runTime'][0] - self.metadata['inhibitTime'][0]

        return flow_rate * looktime / 60

    def get_capture_percent(self, roi_dir, name):
        '''Determines the ratio of triggers to images'''

        with open(f'{roi_dir}/{name[:9]}/{name}_{self.ifcb}.adc', 'r') as adc:
            trigger_count = 0
            for line in adc:
                trigger_count += 1

        return len(self.targets) / trigger_count

    def group(self, feature):
        '''Creates a dictionary representation for a histogram of the targets using some length feature'''

        groups = {num: [] for num in range(200)}
        json_groups = {num: [] for num in range(200)}
        for target in self.targets:
            diameter_group = floor(getattr(target, feature))
            if diameter_group > 199:
                diameter_group = 199
            groups[diameter_group] += [target]
            json_groups[diameter_group] += [target.json]

        setattr(self, f'grouped_{feature}', groups)
        setattr(self, f'grouped_{feature}_json', json_groups)
        return groups

    def export_specific_groups(self, feature):
        return [(len(targets) / self.mL_analyzed) * 1000 for targets in getattr(self, f'grouped_{feature}').values()]

    def export_groups(self):
        return self.data

    def create_histograms(self):
        self.group('equiv_diameter')
        self.group('major_axis_length')
        self.group('minor_axis_length')
        self.psd = self.histogram('equiv_diameter')

    def histogram(self, feature):
        '''Creates a dictionary representation for a histogram of biovolume using some length feature'''

        groups = getattr(self, f'grouped_{feature}')
        histogram = {num: 0 for num in range(200)}

        for diameter, targets in groups.items():
            if targets and self.mL_analyzed:
                histogram[diameter] = (len(targets) / (self.mL_analyzed)) * 1000

        return histogram

    def plot_PSD(self, use_marker, save_graph, start_fit):

        print(f'Graphing {self.name}')

        def power_curve(x, k, n):
            return k * (x ** n)

        def round_sig(x, sig=2):
            try:
                return round(x, sig - int(floor(log10(abs(x)))) - 1)
            except:
                return 0

        xdata, ydata = zip(*self.psd.items())
        maximum = max(ydata)
        max_diff = start_fit - ydata.index(maximum)

        if save_graph:
            fig, ax = plt.subplots()
            ax.set(xlabel="ESD [um]", ylabel="N'(D) [c/L⁻]")
            ax.set_ylim(bottom=-0.1 * maximum, top=1.1 * maximum)

        try:
            popt, pcov, infodict, mesg, ier = curve_fit(power_curve, xdata[start_fit:], ydata[start_fit:],
                                                        full_output=True, p0=[80000, -0.8])
            residuals = ydata[start_fit:] - power_curve(xdata[start_fit:], *popt)
            ss_res = np.sum(residuals ** 2)
            ss_tot = np.sum((ydata[start_fit:] - np.mean(ydata[start_fit:])) ** 2)
            r_sqr = 1 - (ss_res / ss_tot)
            self.bin.add_fit(self.name, round_sig(popt[0], 5), round_sig(popt[1], 5), r_sqr, max_diff, self.capture_percent, self.bead_run, self.humidity)
        except:
            popt = [0.0, 0.0]
            r_sqr = 0
            self.bin.add_fit(self.name, 0,0, r_sqr, max_diff, self.capture_percent, self.bead_run, self.humidity)

        self.bin.add_data(self.name, self.datenum, ydata, self.mL_analyzed, maximum)

        if use_marker:
            marker = 'o'
        else:
            marker = None

        if save_graph:
            psd_line = ax.plot(xdata[start_fit:], xdata[start_fit:],
                               color='#00afbf', marker=marker, linestyle='solid',
                               linewidth=1.25, markersize=4, label='PSD')
            if r_sqr > 0:
                curve_fit_line = ax.plot(xdata, power_curve(xdata[start_fit:], *popt), color='#516b6e', linestyle='dashed',
                                         label='Power Curve')
                ax.text(80, maximum * 0.75,
                        f'$y = ({round_sig(popt[0], 3)})x^{{{round_sig(popt[1], 3)}}}$, $R^{{2}} = {round_sig(r_sqr, 3)}$')

            ax.legend()
            ax.set_title(f'{self.name}')
            plt.savefig(os.path.join(os.getcwd(), 'Graphs', self.name))
            plt.close('all')


class Bin:
    def __init__(self, feature_dir, hdr_dir, samples_path=None):

        fileConvention = r'D\d\d\d\d\d\d\d\dT\d\d\d\d\d\d'
        regex = re.compile(fileConvention)
        files = [(f.split('_')[0], f.split('_')[1]) for f in os.listdir(feature_dir) if regex.search(f)]

        self.samples_loaded = bool(samples_path)
        if self.samples_loaded:
            sample_file = open(samples_path, 'rb')
            samples = json.load(sample_file)["samples"]
            self.samples = [json.loads(json.dumps(s), object_hook=lambda d: Sample(**d)) for s in samples]

        else:
            self.samples = [Sample(f[0], feature_dir, hdr_dir, self, f[1]) for f in files]

        self.file_names = [s.name for s in self.samples]
        self.data = pd.DataFrame(columns=['mL_analyzed', 'max'] + [f'{i}μm' for i in range(0, 200)], index=self.file_names)
        self.fits = pd.DataFrame(columns=['a', 'k', 'R^2', 'max_ESD_diff', 'capture_percent', 'bead_run', 'humidity'],
                                 index=self.file_names)

    def add_data(self, file, datenum, data, mL_analyzed, maximum):

        formatted_data = {f'{i}μm': data[i] for i in range(0, 200)}
        formatted_data['mL_analyzed'] = mL_analyzed
        formatted_data['max'] = maximum
        formatted_data['datenum'] = datenum
        self.data.loc[file] = pd.Series(formatted_data)

    def add_fit(self, file, a, k, r_sqr, max_diff, capture_percent, bead_run, humidity):

        self.fits.loc[file] = pd.Series({'a': a, 'k': k, 'R^2': r_sqr, 'max_ESD_diff': max_diff,
                                         'capture_percent': capture_percent, 'bead_run': bead_run, 'humidity': humidity})

    def pick_start(self):
        files = self.file_names[:]
        months = [[] for m in range(12)]
        for m in range(1, 13):
            month = str(m).zfill(2)
            currFile = files[0]
            while currFile[5:7] == month:
                months[m - 1] += [currFile]
                files = files[1:]
        print(files)
        print()

    def plot_PSD(self, use_marker, save_graphs, start_fit):

        if save_graphs:
            os.mkdir(os.path.join(os.getcwd(), 'Graphs'))
        if not self.samples_loaded:
            for sample in self.samples:
                sample.create_histograms()
        for sample in self.samples:
            sample.plot_PSD(use_marker=use_marker, save_graph=save_graphs, start_fit=start_fit)
        print(f'Start fit: {start_fit}')

    def save_data(self, name, r_sqr=0.5, **kwargs):

        print(f'Saving Data')

        def flag(dataset, op, parameter, threshold, flag_name, priority, low_r_only):
            if low_r_only:
                dataset = dataset[self.fits['R^2'] < r_sqr]

            if type(op) != tuple:
                files = dataset[op(dataset[parameter], threshold)]
            else:
                files = dataset[op[0](dataset[parameter[0]], threshold[0])]
                for i in range(1, len(op)):
                    files = files[op[i](files[parameter[i]], threshold[i])]

            if flag_name == 'Beads':
                calculated_df = pd.DataFrame({'file': list(files.index), 'flag': [flag_name] * len(files), 'priority': priority})
                bead_runs = self.fits[self.fits['bead_run']]
                set_df = pd.DataFrame({'file': list(bead_runs.index), 'flag': [flag_name] * len(bead_runs), 'priority': priority})
                return pd.concat([calculated_df, set_df]).drop_duplicates('file')

            return pd.DataFrame({'file': list(files.index), 'flag': [flag_name] * len(files), 'priority': priority})

        flag_params = {
            'beads': (self.fits, operator.gt, 'a', 'Beads', 1),
            'bubbles': (self.fits, operator.lt, 'max_ESD_diff', 'Bubbles', 2),
            'incomplete': (self.data, (operator.lt, operator.lt), ('max', 'mL_analyzed'), 'Incomplete Run', 3),
            'missing_cells': (self.fits, operator.lt, 'capture_percent', 'Missing Cells', 4),
            'biomass': (self.data, operator.lt, 'max', 'Low Biomass', 5),
            'bloom': (self.fits, operator.lt, 'max_ESD_diff', 'Bloom', 6),
            'humidity': (self.fits, operator.gt, 'humidity', 'High Humidity', 7)
        }

        full_flags = pd.DataFrame({'file': [], 'flag': [], 'priority': 10000})
        r_limited_flags = ['biomass', 'bloom']
        esd_diff_flags = ['bubbles', 'bloom']
        r_flag = flag(self.fits, operator.lt, 'R^2', r_sqr, 'Low R^2', 7, False)
        if len(r_flag['file']) > 0:
            full_flags = pd.concat([full_flags, r_flag], ignore_index=True)

        for key, value in kwargs.items():
            if key in esd_diff_flags:
                value = -value
            [dataset, op, parameter, flag_name, priority] = flag_params[key]
            key_flag = flag(dataset, op, parameter, value, flag_name, priority, key in r_limited_flags)
            if len(key_flag['file']) > 0:
                full_flags = pd.concat([full_flags, key_flag], ignore_index=True)

        flags = full_flags.sort_values('priority').drop_duplicates(subset=['file']).sort_values(by=['file'])
        flags = flags.drop('priority', axis=1)

        self.data.to_csv(f'{name}_data.csv')
        self.fits.to_csv(f'{name}_fits.csv')
        flags.to_csv(f'{name}_flags.csv')
