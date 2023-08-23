## `flairR`: An R Wrapper for Accessing Flair NLP Tagging Features

This R wrapper, built on the reticulate architecture, provides easy access to the core functionalities of FlairNLP in Python. FlairNLP serves as an advanced framework that integrates the latest Natural Language Processing techniques. For details on the architecture of Flair's training model, please refer to the article titled "[Contextual String Embeddings for Sequence Labeling](https://aclanthology.org/C18-1139.pdf)". The current stable features in `flairR` include `part-of-speech tagging`, `transformer-based sentiment analysis`, and `named entity recognition`. The use of flairR is limited to the pre-trained models provided by Flair NLP. 與Flair NLP python 不同的是，flairR直接format 關叫tag的信息成data.table 

This R wrapper, built upon the reticulate architecture, offers streamlined access to the core features of FlairNLP in Python. FlairNLP is an advanced framework incorporating the latest techniques in Natural Language Processing. For a deeper understanding of Flair's training model architecture, please consult the article '[Contextual String Embeddings for Sequence Labeling](https://aclanthology.org/C18-1139.pdf)'. The stable features currently available in `flairR` includes __part-of-speech tagging__, __transformer-based sentiment analysis__, and __named entity recognition__. The utility of flairR is confined to the pre-trained models provided by _Flair NLP_. flairR directly return the taaging information into a data.table format.




###  Cite

```
@inproceedings{akbik2018coling,
  title={Contextual String Embeddings for Sequence Labeling},
  author={Akbik, Alan and Blythe, Duncan and Vollgraf, Roland},
  booktitle = {{COLING} 2018, 27th International Conference on Computational Linguistics},
  pages     = {1638--1649},
  year      = {2018}
}
```


