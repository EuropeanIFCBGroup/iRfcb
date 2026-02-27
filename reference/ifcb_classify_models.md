# List Available CNN Models from a Gradio Classification Server

Queries the Gradio API to retrieve the names of all CNN models available
for IFCB image classification. These model names can be passed to the
`model_name` argument of
[`ifcb_classify_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_images.md)
and
[`ifcb_classify_sample()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_sample.md).

## Usage

``` r
ifcb_classify_models(gradio_url = "https://irfcb-classify.hf.space")
```

## Arguments

- gradio_url:

  A character string specifying the base URL of the Gradio application.
  Default is `"https://irfcb-classify.hf.space"`, which is an example
  Hugging Face Space with limited resources intended for testing and
  demonstration. For large-scale classification, deploy your own
  instance of the classification app with your own model (source code:
  <https://github.com/EuropeanIFCBGroup/ifcb-inference-app>) and pass
  its URL here.

## Value

A character vector of available model names.

## See also

[`ifcb_classify_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_images.md),
[`ifcb_classify_sample()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_sample.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# List available models
models <- ifcb_classify_models()
print(models)

# Use a specific model for classification
result <- ifcb_classify_images("image.png", model_name = models[1])
} # }
```
