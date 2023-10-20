# flaiR 0.0.5 (2023-10-01)

* Added more tests to monitor function operation. 

* Added wrapped functions integrating Python code.

* Created a function for coloring entities.

* Provided some tutorials for interacting with R and Python using Flair.

* add tutorial 


# flaiR 0.0.3 (2023-09-10)

__Modifications Overview__

* Added `show.text_id` and `gc.active` parameters to `get_entities()`, `get_pos()`, and `get_sentiment()`.
  
* Enhanced batch processing with the introduction of `batch_size` in functions `get_entities_batch()`, `get_pos_batch()`, and `get_sentiment_batch()`. Introduced `device` parameter to specify computation device. 


__Introduction of New Parameters:__

  + show.text_id: When activated (TRUE), the actual text (labeled 'text_id') from which the entity was derived will be appended in the resulting dataset. Although enriching the output for validation and traceability, users should be cautious, as this might inflate the output size. By default, this option remains deactivated (FALSE). For context, previously, the 'text_id' was intrinsically generated, potentially elevating R's memory consumption.

  + gc.active: Activating this (TRUE) will trigger the garbage collector post-text processing. This action aids in memory optimization by relinquishing unallocated memory spaces, a crucial step, particularly when processing an extensive text dataset. While the default is set to FALSE, users managing larger texts should consider setting gc.active to TRUE. Though this action doesn't bolster computational efficiency, it does circumvent potential RStudio crashes.
    
__Batch Processing Enhancement:__

The inception of the batch_size parameter (defaulted at 5) in the get_entities_batch(), get_pos_batch(), and get_sentiment_batch() augments their batch processing capabilities. This addition led to the creation of an internal function named process_batch to proficiently manage each text batch and the linked doc_ids. The core functionality has been adapted to segregate the texts and doc_ids into specific batches, subsequently processed via the process_batch function, with the final results amalgamated seamlessly.

  + device: A descriptive character string pinpointing the computation device. Users can opt for "cpu" or a GPU device number in string format. For instance, representing the primary GPU as 0. When a GPU device number is furnished, the system will endeavor to harness that specific GPU, with "cpu" as the default setting.
    
  + batch_size: An integer specifying the size of each batch. Default is 5.


# flaiR 0.0.1 (development version)

* The features in flaiR currently include part-of-speech tagging, sentiment tagging, and named entity recognition tagging.  flaiR requires Python version 3.7  or higher to operate concurrently.

* create_flair_env(): A function to install the Flair Python library using the `reticulate` R package, which is automatically generated.


