module Edgar

  # Provides a little simplistic DSL for building report definitions.
  #
  # app/definitions/schedule_ids_report.yml
  #
  # <<-YAML
  #   :name: 'AdSchedule Ids for campaigs [1, 3, 5]'
  #   :format: CSV
  #   :type: CAMPAIGN_AD_SCHEDULE_TARGET_REPORT
  #   :fields: CampaignId, Id
  #   :predicates:
  #     :field: CampaignId
  #     :operator: IN
  #     :values: 1, 3, 5
  #   :date: YESTERDAY
  #   :zero_impressions: true
  # YAML
  #
  # definition = Edgar::ReportDefinition.new('SCHEDULE IDS REPORT')
  #
  class ReportDefinition < Hash
    def initialize(name)
      definition = YAML.load(
        File.read(File.join(
          Edgar::Engine.root,
          'app', 'definitions',
          "#{name.downcase.gsub(' ', '_')}.yml"
        )))

      self[:selector] = {}
      self[:selector][:date_range] = {}

      self[:report_name] = definition[:name]
      self[:download_format] = definition[:format]
      self[:report_type] = definition[:type]
      self[:selector][:fields] = strip(definition[:fields])

      if definition[:predicates]
        self[:selector][:predicates] = {}
        definition[:predicates][:fields] = strip(definition[:predicates][:fields])
        definition[:predicates][:values] = strip(definition[:predicates][:values])
        self[:selector][:predicates] = definition[:predicates]
      end

      self[:date_range_type] = definition[:date]

      self[:selector][:date_range] = {}
      self[:selector][:date_range][:max] = definition[:date_max] || Time.current.strftime('%Y%m%d')
      self[:selector][:date_range][:min] = definition[:date_min] || (Time.current - 30.days).strftime('%Y%m%d')

      self[:order!] = {}
      self[:order!][:include_zero_impressions] = definition[:zero_impressions]
    end 

    private

    def strip(string)
      string.gsub(' ', '').split(',')
    end
  end
end
