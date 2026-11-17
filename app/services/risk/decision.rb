module Risk
  # Turns a score into what the system should do next.
  module Decision
    def self.review_threshold = ENV.fetch("RISK_REVIEW_THRESHOLD", 70).to_i
    def self.extended_hold_threshold = ENV.fetch("RISK_EXTENDED_HOLD_THRESHOLD", 40).to_i

    def self.for(score)
      return :needs_human  if score >= review_threshold
      return :extended_hold if score >= extended_hold_threshold

      :auto_hold
    end
  end
end
