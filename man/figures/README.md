
## <u>`flairR`</u>: An R Wrapper for Accessing Flair NLP Tagging Features <img src="man/figures/logo.png" align="right" width="180"/>

[![R](https://github.com/davidycliao/flaiR/actions/workflows/r2.yml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/r2.yml)
[![R-CMD-check](https://github.com/davidycliao/flaiR/actions/workflows/r.yml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/r.yml)
[![R-CMD-check](https://github.com/davidycliao/flaiR/actions/workflows/R-CMD-check2.yml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/R-CMD-check2.yml)
[![coverage](https://github.com/davidycliao/flaiR/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/davidycliao/flaiR/actions/workflows/test-coverage.yaml)
[![codecov](https://codecov.io/gh/davidycliao/flaiR/graph/badge.svg?token=CPIBIB6L78)](https://codecov.io/gh/davidycliao/flaiR)
[![CodeFactor](https://www.codefactor.io/repository/github/davidycliao/flair/badge)](https://www.codefactor.io/repository/github/davidycliao/flair)

<!-- README.md is generated from README.Rmd. Please edit that file -->

<div style="text-align: justify">

`flaiR` is a R wrapper of the FlairNLP for R users, particularly for
social science researchers. It offers streamlined access to the core
features of `FlairNLP` from Python. FlairNLP is an advanced NLP
framework that incorporates the latest techniques developed by the
Humboldt University of Berlin. For a deeper understanding of Flair’s
architecture, refer to the research article ‘[Contextual String
Embeddings for Sequence
Labeling](https://aclanthology.org/C18-1139.pdf)’ and the official
[mannual](https://flairnlp.github.io) in Python. The features currently
available in `flairR` include **part-of-speech tagging**,
**transformer-based sentiment analysis**, and **named entity
recognition**. `flairR` returns extracted features in a tidy and clean
[`data.table`](https://cran.r-project.org/web/packages/data.table/index.html).

</div>

<br>

| **The Main Features in R**                   | Loader                     | Supported Models                                                                                                        |
|----------------------------------------------|----------------------------|-------------------------------------------------------------------------------------------------------------------------|
| `get_entities()`, `get_entities_batch()`     | `load_tagger_ner()`        | `en` (English), `fr` (French), `da` (Danish), `nl` (Dutch), and more.                                                   |
| `get_pos()`, `get_pos_batch()`               | `load_tagger_pos()`        | `pos` (English POS), `fr-pos` (French POS), `de-pos` (German POS), `nl-pos` (Dutch POS), and more.                      |
| `get_sentiments()`, `get_sentiments_batch()` | `load_tagger_sentiments()` | `sentiment` (English) , `sentiment-fast`(English) , `de-offensive-language` (German offensive language detection model) |

<br>

### Installation via <u>**`GitHub`**</u>

The installation consists of two parts: First, install [Python
3.7](https://www.python.org/downloads/) or higher, and [R
3.6.3](https://www.r-project.org) or higher. Although we have tested it
on Github Action with R 3.6.2, we strongly recommend installing R 4.2.1
to ensure compatibility between the R environment and {`reticulate`}. If
there are any issues with the installation, feel free to ask in the
<u>[Discussion](https://github.com/davidycliao/flaiR/discussions) </u>.

``` r
install.packages("remotes")
remotes::install_github("davidycliao/flaiR", force = TRUE)
library(flaiR)
```

## Example

### NER with the State-of-the-Art German Pre-trained Model

``` r
library(flaiR)
data("de_immigration")
de_immigration <- de_immigration[5,]
tagger_ner <- load_tagger_ner("de-ner")
#> 2023-10-01 22:19:06,451 SequenceTagger predicts: Dictionary with 19 tags: O, S-LOC, B-LOC, E-LOC, I-LOC, S-PER, B-PER, E-PER, I-PER, S-ORG, B-ORG, E-ORG, I-ORG, S-MISC, B-MISC, E-MISC, I-MISC, <START>, <STOP>
result <- get_entities(de_immigration$text,
                       tagger = tagger_ner,
                       show.text_id = FALSE
                       )
#> Warning in check_texts_and_ids(texts, doc_ids): doc_ids is NULL. Auto-assigning
#> doc_ids.
```

``` r
head(result, 5)
#>    doc_id                                  entity tag
#> 1:      1                            Griechenland LOC
#> 2:      1                            Griechenland LOC
#> 3:      1 Bundesamt für Migration und Flüchtlinge ORG
#> 4:      1                            Griechenland LOC
#> 5:      1                            Griechenland LOC
```

### Coloring Entities

``` r
highlighted_text <- highlight_text(text = de_immigration$text, 
                                   entities_mapping = map_entities(result))
highlighted_text
```

<div style="text-align: justify; font-family: Arial">Das <span style="background-color: pink; color: black; font-family: Arial">Bundesverfassungsgericht</span> <span style="color: pink; font-family: Arial">(ORG)</span> hat unterdessen die Aussetzung der Abschiebung von Asylsuchenden nach <span style="background-color: lightblue; color: black; font-family: Arial">Griechenland</span> <span style="color: blue; font-family: Arial">(LOC)</span> im Rahmen des <span style="background-color: pink; color: black; font-family: Arial">EU</span> <span style="color: pink; font-family: Arial">(ORG)</span>-Verteilungssystems, der Dublin-II-Verordnung, in acht Einzelfällen angeordnet. Das Gericht stützt sich dabei auf „ernst zu nehmende Quellen“, wonach eine ordnungsgemäße Registrierung als Asylsuchender in <span style="background-color: lightblue; color: black; font-family: Arial">Griechenland</span> <span style="color: blue; font-family: Arial">(LOC)</span> unmöglich sein könnte. Trotz der mittlerweile ergangenen acht einstweiligen Anordnungen des BundesverfassungsgeZu Protokoll gegebene Reden richts betreibt das <span style="background-color: pink; color: black; font-family: Arial">Bundesamt für Migration und Flüchtlinge</span> <span style="color: pink; font-family: Arial">(ORG)</span> weiterhin die Rückschiebung von Asylsuchenden nach <span style="background-color: lightblue; color: black; font-family: Arial">Griechenland</span> <span style="color: blue; font-family: Arial">(LOC)</span>. Dies wollen wir mit dem vorliegenden Antrag verhindern. Denn das Asylverfahren in <span style="background-color: lightblue; color: black; font-family: Arial">Griechenland</span> <span style="color: blue; font-family: Arial">(LOC)</span> ist weiterhin eine Frage des Zufallsprinzips. Nicht nur <span style="background-color: pink; color: black; font-family: Arial">Pro Asyl</span> <span style="color: pink; font-family: Arial">(ORG)</span> und <span style="background-color: pink; color: black; font-family: Arial">Human Rights Watch</span> <span style="color: pink; font-family: Arial">(ORG)</span>, sondern auch der <span style="background-color: pink; color: black; font-family: Arial">UNHCR</span> <span style="color: pink; font-family: Arial">(ORG)</span> berichten, dass das Asylverfahren in <span style="background-color: lightblue; color: black; font-family: Arial">Griechenland</span> <span style="color: blue; font-family: Arial">(LOC)</span> in vielerlei Hinsicht an erheblichen Mängeln leidet. Von einem fairen Verfahren, wie es nach dem internationalen Flüchtlingsrecht und den <span style="background-color: pink; color: black; font-family: Arial">EU</span> <span style="color: pink; font-family: Arial">(ORG)</span>-Richtlinien über die Aufnahme von Flüchtlingen, die Durchführung des Asylverfahrens und die Kriterien für die Anerkennung als Flüchtling vorgesehen ist, kann man nicht sprechen. So kommen Inhaftierungen ohne Haftgrund vor, Dolmetscher bei der Befragung über die Fluchtgründe sind nicht garantiert, es gibt keine Unterbringung während des Asylverfahrens, der Zugang zur zentralen Asylbehörde in <span style="background-color: lightblue; color: black; font-family: Arial">Athen</span> <span style="color: blue; font-family: Arial">(LOC)</span> ist nur an einem einzigen Tag möglich. Dies alles räumt das <span style="background-color: pink; color: black; font-family: Arial">BMI</span> <span style="color: pink; font-family: Arial">(ORG)</span> auch in zahlreichen Stellungnahmen an den Petitionsausschuss des <span style="background-color: pink; color: black; font-family: Arial">Bundestages</span> <span style="color: pink; font-family: Arial">(ORG)</span> ein, will die Menschen aber dennoch weiter zurückschicken. Das ist aus grüner Sicht untragbar, denn <span style="background-color: lightblue; color: black; font-family: Arial">Deutschland</span> <span style="color: blue; font-family: Arial">(LOC)</span> trägt angesichts dieser dem Bundesinnenministerium schon länger bekannten Situation in <span style="background-color: lightblue; color: black; font-family: Arial">Griechenland</span> <span style="color: blue; font-family: Arial">(LOC)</span> gerade auch für rücküberstellte Personen aus <span style="background-color: lightblue; color: black; font-family: Arial">Deutschland</span> <span style="color: blue; font-family: Arial">(LOC)</span> eine Mitverantwortung. Aus unserer Sicht sollte <span style="background-color: lightblue; color: black; font-family: Arial">Deutschland</span> <span style="color: blue; font-family: Arial">(LOC)</span> die Asylverfahren hier in <span style="background-color: lightblue; color: black; font-family: Arial">Deutschland</span> <span style="color: blue; font-family: Arial">(LOC)</span> durchführen. Auch bei hohen Zugangszahlen von Asylantragstellern muss ein faires Verfahren unter Einhaltung der Mindeststandards aus der <span style="background-color: pink; color: black; font-family: Arial">EU</span> <span style="color: pink; font-family: Arial">(ORG)</span>-Flüchtlingsaufnahme-Richtlinie, der <span style="background-color: pink; color: black; font-family: Arial">EU</span> <span style="color: pink; font-family: Arial">(ORG)</span>-Asylverfahrens-Richtlinie und der EUQualifikations-Richtlinie erfolgen. Die südlichen Außengrenzländer der <span style="background-color: pink; color: black; font-family: Arial">EU</span> <span style="color: pink; font-family: Arial">(ORG)</span> haben mit einer großen Zahl schutzsuchender Menschen zu tun: <span style="background-color: lightblue; color: black; font-family: Arial">Griechenland</span> <span style="color: blue; font-family: Arial">(LOC)</span> vor allem mit Flüchtlingen aus dem <span style="background-color: lightblue; color: black; font-family: Arial">Irak</span> <span style="color: blue; font-family: Arial">(LOC)</span>, <span style="background-color: lightblue; color: black; font-family: Arial">Afghanistan</span> <span style="color: blue; font-family: Arial">(LOC)</span>, <span style="background-color: lightblue; color: black; font-family: Arial">Iran</span> <span style="color: blue; font-family: Arial">(LOC)</span>. Viele dieser Menschen haben schwerste Menschenrechtsverletzungen durchlitten und suchen nach einem sicheren Platz. <span style="background-color: lightblue; color: black; font-family: Arial">Deutschland</span> <span style="color: blue; font-family: Arial">(LOC)</span> sollte sich intensiv für eine Neuregelung der Verteilungsregelung innerhalb der <span style="background-color: pink; color: black; font-family: Arial">EU</span> <span style="color: pink; font-family: Arial">(ORG)</span> einsetzen. Bis zu einer Neuregelung darf aber das Prinzip der „Verknappung von Zugangsmöglichkeiten zum Asylverfahren“ in <span style="background-color: lightblue; color: black; font-family: Arial">Griechenland</span> <span style="color: blue; font-family: Arial">(LOC)</span> nicht weiterpraktiziert werden. Denn es trifft Opfer von Menschenrechtsverletzungen. Dies ist nicht hinzunehmen. Bestätigt in dieser Haltung fühlen wir uns auch durch das <span style="background-color: pink; color: black; font-family: Arial">Bundesverfassungsgericht</span> <span style="color: pink; font-family: Arial">(ORG)</span>: Dieses hat erneut mit Beschluss vom 8. Dezember 2009 die Aussetzung der Abschiebung eines Asylsuchenden nach <span style="background-color: lightblue; color: black; font-family: Arial">Griechenland</span> <span style="color: blue; font-family: Arial">(LOC)</span> im Rahmen des <span style="background-color: pink; color: black; font-family: Arial">EU</span> <span style="color: pink; font-family: Arial">(ORG)</span>-Verteilungssystems Nr. 343/2003 des Rates vom 18. Februar 2003, Dublin-II-Verordnung) angeordnet. Dafür war wie in dem der einstweiligen Anordnung vom 8. September 2009 – 2 BvQ 56/09 – zugrunde liegenden Fall ausschlaggebend, dass möglicherweise bereits mit der Abschiebung oder in ihrer Folge eintretende Rechtsbeeinträchtigungen nicht mehr verhindert oder rückgängig gemacht werden könnten. Zwar wird die Rückschiebung besonders schutzbedürftiger Flüchtlinge nach <span style="background-color: lightblue; color: black; font-family: Arial">Griechenland</span> <span style="color: blue; font-family: Arial">(LOC)</span> in der Regel nicht vollzogen, die Argumentation des <span style="background-color: pink; color: black; font-family: Arial">Bundesamtes für Migration</span> <span style="color: pink; font-family: Arial">(ORG)</span> und Flüchtlinge, dass man von Asylbewerbern, die nicht besonders schutzbedürftig sind, erwarten könne, dass sie auch unter gegebenenfalls erschwerten Bedingungen das Asylverfahren in <span style="background-color: lightblue; color: black; font-family: Arial">Griechenland</span> <span style="color: blue; font-family: Arial">(LOC)</span> durchführten – Drucksache 16/14149 –, ist aber menschenrechtlich höchst bedenklich. Die Antragsteller der bisherigen positiven Eilverfahren vor dem <span style="background-color: pink; color: black; font-family: Arial">Bundesverfassungsgericht</span> <span style="color: pink; font-family: Arial">(ORG)</span> gehörten gerade nicht dem Kreis besonders schutzbedürftiger Personen an, bei denen die Bundesrepublik <span style="background-color: lightblue; color: black; font-family: Arial">Deutschland</span> <span style="color: blue; font-family: Arial">(LOC)</span> vom Selbsteintrittsrecht gemäß Art. 3 Abs. 2 der Dublin-IIVerordnung Gebrauch macht. Wenn aber das <span style="background-color: pink; color: black; font-family: Arial">Bundesverfassungsgericht</span> <span style="color: pink; font-family: Arial">(ORG)</span> die Verletzung elementarer Rechte in <span style="background-color: lightblue; color: black; font-family: Arial">Griechenland</span> <span style="color: blue; font-family: Arial">(LOC)</span> für möglich hält und deswegen nach einer Abwägung die Rückführung unterbindet, darf sich die Bundesregierung dem nicht verschließen. Dennoch Rückführungen vorzunehmen, ist nicht nur eine Brüskierung des Bundesverfassungsgerichts, sondern heißt auch, die Menschenwürde der Asylsuchenden sehenden Auges zu gefährden. Daher fordern wir, Rückschiebungen nach <span style="background-color: lightblue; color: black; font-family: Arial">Griechenland</span> <span style="color: blue; font-family: Arial">(LOC)</span> im Rahmen des Dublin-II-Verfahrens sofort bis zur Hauptsacheentscheidung des Bundesverfassungsgerichts auszusetzen und die Prüfung der Asylanträge im Rahmen des Selbsteintritts im nationalen Asylverfahren durchzuführen.</div>

<br>

### Citing the Contributions of `Flair`

<div style="text-align: justify">

If you use this tool in academic research, we recommend citing the
research article, [Contextual String Embeddings for Sequence
Labeling](https://aclanthology.org/C18-1139.pdf) from `Flair` research
team.

</div>

    @inproceedings{akbik2018coling,
      title={Contextual String Embeddings for Sequence Labeling},
      author={Akbik, Alan and Blythe, Duncan and Vollgraf, Roland},
      booktitle = {{COLING} 2018, 27th International Conference on Computational Linguistics},
      pages     = {1638--1649},
      year      = {2018}
    }
