# Metadata template

This R Markdown document is based on a template provided by the
[`LivingNorwayR`](https://livingnorway.github.io/LivingNorwayR/)
package, and is used for creating a `.eml` file in
`vignette("dwca-tutorial")`.

When documenting project metadata in Markdown, the `LivingNorwayR`
package provides various functions to flag specific text sections for
export into an EML file. The code chunk below highlights these flagged
sections in red when rendered in HTML output. However, for standard
metadata descriptions, this highlighting is typically unnecessary, so
you should remove this code chunk when creating your own metadata
descriptions.

``` css
span.LNmetadata {
  color: red;
}
```

## The Dataset

Metadata must include a dataset tag, which requires an ID. This ID acts
as a parent identifier for numerous other tags that describe the
dataset. In many cases, you may not want any text associated with this
tag to appear in the output. To achieve this, set the `isHidden`
argument to `TRUE`, making the tag invisible in the rendered output. The
primary purpose of this function is to assign an ID to the `dataset` tag
(e.g., **iRfcbDataset**), enabling other elements to reference it.
Additionally, you can provide a title for the dataset using the
`title.tagText` argument within the function.

iRfcb Test Data

We can associate keywords with the dataset by creating a `keywordSet`
tag using the appropriate tagging function. For example: . Next,
individual keywords can be specified within this keywordSet using the
LNkeyword function. Examples include: Imaging FlowCytobot,
phytoplankton, microzooplankton, imaging and sampling event.

We must also specify some contact information for the individual or
organization responsible for coordinating with users of the dataset.
Here the responsible user is Anders Torstensson. This approach ensures
that all keywords are grouped under the `iRfcbKeywordSet` tag, which is
linked to the dataset through its `parentID`.

## Abstract

An abstract for the dataset is required. You can flag the abstract for
export to EML using the following inline code:

Imaging FlowCytobot sample data from the iRfcb R package, collected
onboard R/V Svea between 2022 and 2023.

The `LivingNorwayR` package also supports adding alternative
translations for EML elements. In the inline code above, we specified
the `tagID` argument. To provide an alternative translation for the
element associated with that `tagID`, you can use the following code:

Exempeldata från Imaging FlowCytobot i iRfcb R-paketet, insamlade ombord
R/V Svea mellan 2022 och 2023.

By default, alternative translations are hidden in the rendered HTML
output. While the information is included in the file, it is not visible
when viewed in a browser. This is useful when you want the translation
to be exported to the EML file without appearing in the rendered HTML.
If you prefer the alternative translation to be displayed, simply add
the argument `isHidden = FALSE` to the `LNaddTranslation` function.

## Dataset creators

The dataset was created by the following people:

- Anders Torstensson who is a researcher at the Swedish Meteorological
  and Hydrological Institute (<anders.torstensson@smhi.se>).
