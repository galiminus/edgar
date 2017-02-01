module Edgar
  class Report < ::ActiveRecord::Base
    self.table_name = 'edgar_reports'
    include AASM

    aasm whiny_transitions: false do
      state :pending, initial: true
      state :ready, :processed

      event :replenish, after: :process do
        transitions from: :pending, to: :ready, if: :ready?
      end

      event :finalise do
        transitions from: :ready, to: :processed, if: :processed?
      end
    end

    scope :completion, -> { order(aasm_state: :desc) }

    def youtube_earned_data
      data = JSON.parse(self.youtube_earned_data_raw)
      data[1..-1]
      .map do |e|
        e.zip(
          data[0].map do |e|
            e.downcase.gsub('youtube ','')
            .gsub(' ', '_')
            .gsub(/[.%]+/, '').to_sym
          end
        ).map(&:reverse)
        .map do |e|
          e[0].to_s.include?('campaign') ? e : [e[0], e[1].to_f]
        end.to_h
      end
    end

    def youtube_data
      JSON.parse(self.youtube_data_raw)
    end

    def adwords_data
      data = JSON.parse(self.adwords_data_raw)

      labels = data[1].tap{ |e| e.delete_at(0) }
      .map{ |e| e.downcase.gsub(' ', '_').gsub(/[.()%]+/, '').to_sym }

      lines = data[1..-2].tap{ |e| e.delete_at(0) }.map do |line|
        labels.zip(
          line.tap{ |e| e.delete_at(0) }
        ).map{ |e| e[0].to_s.include?('campaign') ? e : [e[0], e[1].to_f] }.to_h
      end

      totals = labels.zip(data[-1].tap{ |e| e.delete_at(0) })
      .map{ |e| e[0].to_s.include?('campaign') ? e : [e[0], e[1].to_f] }.to_h

      { labels: labels, lines: lines, totals: totals }
    end

    def to_csv
      return nil unless self.aasm_state == 'processed'

      CSV.generate do |csv|
        csv << self.body[:values].keys << self.body[:values].values
      end
    end

    def has_youtube_earned_data?
      self.youtube_earned_data_raw?
    end

    def has_youtube_data?
      self.youtube_data_raw.present?
    end

    def has_adwords_data?
      self.adwords_data_raw.present?
    end

    def stamps
      [
        (self.has_youtube_data? ? :youtube : nil),
        (self.has_youtube_earned_data? ? :youtube_earned : nil),
        (self.has_adwords_data? ? :adwords : nil)
      ].compact
    end

    private

    def process
      Edgar::DailyReportReplenishmentWorker.perform_async(self.id)
    end

    def ready?
      [
        self.adwords_data_raw.present?,
        self.youtube_data_raw.present?,
        self.youtube_earned_data_raw.present?
      ].all?
    end

    def processed?
      self.body.present?
    end
  end
end
