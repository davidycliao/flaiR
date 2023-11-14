#' @title UK House of Commons Immigration Debate Data
#'
#' @description A dataset containing speeches and debates from the UK House of Commons on the
#' topic of immigration in 2010.
#'
#' @format A data frame with 12 variables:
#' \describe{
#'   \item{date}{Date of the speech, Date type}
#'   \item{agenda}{Agenda or subject of the speech, character}
#'   \item{speechnumber}{Unique identifier for each speech, numeric}
#'   \item{speaker}{Name of the person giving the speech, character}
#'   \item{party}{Political party of the speaker, character}
#'   \item{party.facts.id}{ID for the party, usually a numeric or character}
#'   \item{chair}{Person chairing the session, character}
#'   \item{terms}{Terms or tags associated with the speech, character or list}
#'   \item{text}{Actual text of the speech, character}
#'   \item{parliament}{Which parliament session, character or numeric}
#'   \item{iso3country}{ISO3 country code where the
#'   parliament is located, character}
#'   \item{year}{Year when the speech was made, numeric}
#' }
#' @source Data collected from `ParSpeechV2` the House of Commons for the
#' year 2010. The dataset is publicly available at
#' \url{https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/L4OAKN}.
#' @examples
#' \dontrun{
#' data(uk_immigration)
#' head(uk_immigration)
#' }
#' @docType data
#' @usage data("uk_immigration")
#' @name uk_immigration
NULL

#' @title German Bundestag Immigration Debate Data
#'
#' @description A dataset containing speeches and debates from the German Bundestag on the
#' topic of immigration.
#'
#' @format A data frame with 16 variables:
#' \describe{
#'   \item{date}{Date of the speech, Date type}
#'   \item{agenda}{Agenda or subject of the speech, character}
#'   \item{speechnumber}{Unique identifier for each speech, numeric}
#'   \item{speaker}{Name of the person giving the speech, character}
#'   \item{party}{Political party of the speaker, character}
#'   \item{party.facts.id}{ID for the party, usually numeric or character}
#'   \item{chair}{Person chairing the session, character}
#'   \item{terms}{Terms or tags associated with the speech, character or list}
#'   \item{text}{Actual text of the speech, character}
#'   \item{parliament}{Which Bundestag session, character or numeric}
#'   \item{iso3country}{ISO3 country code for Germany, character}
#'   \item{year}{Year when the speech was made, numeric}
#'   \item{agenda_ID}{Unique identifier for the agenda, usually numeric
#'    or character}
#'   \item{migration_dummy}{Dummy variable related to migration topic,
#'   usually numeric (0 or 1)}
#'   \item{comment_agenda}{Additional comments on the agenda, character}
#' }
#' @source Data collected from `ParSpeechV2` the House of Commons for the
#' year 2010. The dataset is publicly available at
#' \url{https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/L4OAKN}.
#' @examples
#' \dontrun{
#' data(de_immigration)
#' head(de_immigration)
#' }
#' @docType data
#' @usage data("de_immigration")
#' @name de_immigration
NULL


#' @title Replication Data for: The Temporal Focus of Campaign Communication (2020 JOP)
#'
#' @description The replication data is sourced from "The Temporal Focus of Campaign
#' Communication," authored by Stefan Müller, and was published in the Journal of Politics in 2022.
#' This study primarily delves into the temporal emphasis of party manifestos. The dataset
#' encompasses 5,858 annotated data entries from countries such as the United Kingdom,
#' Ireland, Canada, Australia, New Zealand, and the United States. Its central objective
#' is to compute the percentage of sentences or quasi-sentences referring to the past, present,
#' or future. This differentiation is made based on two categories: "Prospective" and "Retrospective".
#' The paper can be accessed at \url{https://www.journals.uchicago.edu/doi/10.1086/715165}.
#'
#' @format A data frame with 7 variables:
#' \describe{
#'   \item{text}{Content of the text.}
#'   \item{sentence_id}{Unique identifier for each sentence.}
#'   \item{countryname}{Country's name.}
#'   \item{party}{Associated political party of the text.}
#'   \item{date}{Date of the record.}
#'   \item{class}{Type or classification.}
#'   \item{class_pro_retro}{Classification as either 'Prospective' or 'Retrospective'.}
#' }
#'
#' @source Data provided by the author
#' and \url{https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/7NP2XH}
#' @examples
#' \dontrun{
#' data(cc_muller)
#' head(cc_muller)
#' }
#' @docType data
#' @usage data("cc_muller")
#' @name cc_muller
NULL


#' @title Sampled Development Set from the Paper: "Political Hate Speech Detection and Lexicon Building: A Study in Taiwan" (IEEE Explore 2022)
#'
#' @description This dataset is derived from the development set of "Political Hate Speech Detection and Lexicon Building: A Study in Taiwan." It contains 1,000 annotated data entries, of which 926 are labeled as '0' (not hate speech) and 74 as '1' (hate speech).
#'
#' The paper can be accessed at \url{https://ieeexplore.ieee.org/document/9738642}.
#'
#' @format A data frame with 2 variables:
#' \describe{
#'   \item{text}{Content of the text.}
#'   \item{label}{Label indicating whether the text is hate speech: '1' for hate speech and '0' for non-hate speech.}
#' }
#'
#' @source Data provided by the authors Chih-Chien Wang, Min-Yuh Day, and Chun-Lian Wu. Available at \url{https://ieeexplore.ieee.org/document/9738642}.
#' @examples
#' \dontrun{
#' data(hatespeech_zh_tw)
#' head(hatespeech_zh_tw)
#' }
#' @docType data
#' @usage data("hatespeech_zh_tw")
#' @name hatespeech_zh_tw
NULL






