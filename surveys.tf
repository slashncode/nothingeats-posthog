# The post-delivery survey, shown once after the tracking page showed an arrival
# (order_delivered_seen). posthog-js picks the translation by the language on screen
# (override_display_language, nothingeats-web). Built in the UI in phase 4; its English
# translations were PostHog's placeholder ("Give us feedback on our product!") until they moved here.
resource "posthog_survey" "post_delivery" {
  name                     = "Wie befriedigend war nichts?"
  type                     = "popover"
  schedule                 = "once"
  start_date               = "2026-10-28T18:36:17.583000Z"
  enable_partial_responses = true

  # No question ids: PostHog keeps the ones it assigned, and the provider leaves them out of the
  # comparison.
  questions_json = jsonencode([
    {
      type                   = "rating"
      display                = "number"
      scale                  = 10
      isNpsQuestion          = true
      question               = "Wie befriedigend war nichts?"
      description            = ""
      descriptionContentType = "text"
      lowerBoundLabel        = "Unbefriedigend."
      upperBoundLabel        = "Herrlich!"
      buttonText             = "Absenden"
      skipSubmitButton       = true
      translations = {
        en = {
          question        = "How satisfying was nothing?"
          description     = ""
          lowerBoundLabel = "Unsatisfying."
          upperBoundLabel = "Delicious!"
          buttonText      = "Submit"
        }
      }
    },
    {
      type                   = "open"
      optional               = true
      question               = "Was hat dir am Nichts am besten geschmeckt?"
      description            = ""
      descriptionContentType = "text"
      buttonText             = "Absenden"
      translations = {
        en = {
          question    = "What did you like best about the nothing?"
          description = ""
          buttonText  = "Submit"
        }
      }
    },
  ])

  conditions_json = jsonencode({
    events = { values = [{ name = "order_delivered_seen" }] }
  })

  translations_json = jsonencode({
    en = {
      name                  = "How satisfying was nothing?"
      thankYouMessageHeader = "Thank you for your feedback!"
    }
  })

  appearance_json = jsonencode({
    position                = "right"
    maxWidth                = "300px"
    zIndex                  = "2147482647"
    borderRadius            = "10px"
    boxPadding              = "20px 24px"
    boxShadow               = "0 4px 12px rgba(0, 0, 0, 0.15)"
    fontFamily              = "inherit"
    backgroundColor         = "#eeeded"
    borderColor             = "#c9c6c6"
    inputBackground         = "white"
    textSubtleColor         = "#939393"
    ratingButtonColor       = "white"
    ratingButtonActiveColor = "black"
    submitButtonColor       = "black"
    submitButtonTextColor   = "white"
    disabledButtonOpacity   = "0.6"
    placeholder             = "Start typing..."
    tabPosition             = "right"
    whiteLabel              = false
    allowGoBack             = false
    autoDisappear           = true
    shuffleQuestions        = false
    displayThankYouMessage  = true
    thankYouMessageHeader   = "Danke für dein Feedback!"
  })
}
