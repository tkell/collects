class ApplicationMailer < ActionMailer::Base
  RESPONSE_EMOJIS = ['🩵','💓', '🎵', '🛸', '🔊'].freeze
  TEXT_ARTS = [
    '>§»',
    '¤⁀℮⁀⎀',
    '⁁⁂Ɲ‱ܐ',
  ].freeze

  default from: ENV.fetch("MAILER_FROM", "noreply@tessellates.space")
  layout "mailer"
end
