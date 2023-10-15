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
#' @source Describe the source of your data here.
#' @examples
#' \dontrun{
#' data(de_immigration)
#' head(de_immigration)
#' }
#' @docType data
#' @usage data("de_immigration")
#' @name de_immigration
NULL
