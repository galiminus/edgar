module Edgar

  # Provides a small DSL for building report definitions.
  #
  #   definition = Definition.new do
  #     name 'AdSchedule Ids for campaign lambda'
  #     format 'CSV'
  #     type 'CAMPAIGN_AD_SCHEDULE_TARGET_REPORT'
  #     fields 'CampaignId', 'Id'
  #     predicates({
  #       field: :CampaignId,
  #       operator: :IN,
  #       values: campaign_ids
  #     })
  #     date 'YESTERDAY'
  #     zero_impressions true
  #   end
  #
  class Definition < Hash
    def initialize
      self[:selector] = {}
    end

    def name(value)
      self[:report_name] = value
    end

    def format(value)
      self[:download_format] = value
    end

    def type(value)
      self[:report_type] = value
    end

    def fields(*value)
      self[:selector][:fields] = value
    end

    def predicates(*value)
      self[:selector][:predicates] = value
    end

    def date(value)
      self[:date_range_type] = value
    end

    def date_max(value)
      self[:selector][:date_range] ||= {}
      self[:selector][:date_range][:max] = value
    end

    def date_min(value)
      self[:selector][:date_range] ||= {}
      self[:selector][:date_range][:min] = value
    end

    def zero_impressions(value)
      self[:include_zero_impressions] = value
    end

    # Predefined definition.
    def self.all_ad_schedules(campaign_ids)
      Definition.new do
        name "AdScheduled Ads for campaigns #{ campaign_ids.join(', ') }"
        format 'CSV'
        type 'CAMPAIGN_AD_SCHEDULE_TARGET_REPORT'
        fields 'CampaignId', 'Id'
        predicates({
          field: :CampaignId,
          operator: :IN,
          values: campaign_ids
        })
        date 'YESTERDAY'
        zero_impressions true
      end
    end

    # Predefined definition.
    def self.today_ad_schedules(campaign_ids)
      Definition.new do
        name "AdScheduled Ads for campaigns #{ campaign_ids.join(', ') }"
        format 'CSV'
        type 'CAMPAIGN_AD_SCHEDULE_TARGET_REPORT'
        fields 'CampaignId', 'Id', 'BidModifier'
        predicates({
          field: :CampaignId,
          operator: :IN,
          values: campaign_ids
        })
        date 'TODAY'
        zero_impressions true
      end
    end
  end
end
