module Edgar

  # Provides a small API wrapper for Google Adwords.
  #
  #   client = Edgar::AdwordsClent.new(Team.first)
  #
  # Issue a request on behalf of a customer account.
  #
  #   client.for(some_customer_id).report(some_report_definition)
  #
  # Get all managed accounts.
  #
  #   selector = { fields: ['CustomerId',  'Name'], paging: { start_index: 0, number_results: 100 } }
  #   client.service(:accounts).get(selector)
  #
  # Available services.
  #
  #   :batch_job: BatchJobService
  #   :account_labels: AccountLabelService
  #   :accounts: ManagedCustomerService
  #   :budgets: :BudgetService
  #   :bidding_stategies: BiddingStrategyService
  #   :bid_stategies: BiddingStrategyService
  #   :budget_orders: BudgetOrderService
  #   :campaigns: CampaignService
  #   :ad_groups: AdGroupService
  #   :bidding: biddingStrategyService
  #   :data: DataService
  #   :ad_schedule: CampaignCriterionService
  #   :estimator: TrafficEstimatorService
  #   :ads: AdGroupAdService
  #   :expanded_text_ads: AdGroupAdService
  #   :keywords: AdGroupCriterionService
  #   :locations: CampaignCriterionService
  #   :languages: CampaignCriterionService
  #   :proximities: CampaignCriterionService
  #   :conversions: ConversionTrackerService
  #   :feeds: FeedService
  #   :feed_mappings: FeedMappingService
  #   :feed_items: FeedItemService
  #   :customer_feeds: CustomerFeedService
  #
  class AdwordsClient
    def initialize(account)
      @globals = YAML.load(File.read(File.join(Edgar::Engine.root, 'config', 'adwords_globals.yml')))
      configuration = YAML.load(File.read(File.join(Edgar::Engine.root, 'config', 'adwords_api.yml')))
      @api = AdwordsApi::Api.new(configuration)
      @cache = Redis.new
      @status = :offline

      credentials = @api.credential_handler()
      credentials.set_credential(
        :oauth2_token,
        { refresh_token: account.adwords_refresh_token, expires_at: 0 }
      )
      credentials.set_credential(
        :client_customer_id,
        configuration[:authentication][:client_customer_id].gsub('-', '')
      )
    end

    def status
      @status
    end

    def core
      @api
    end

    def connect
      @status = :online if @api.authorize
    end
    
    def for(id)
      id = id.gsub('-', '') if id.is_a? String
      @api.credential_handler.set_credential(:client_customer_id, id)
      return self
    end

    def service(type)
      @api.service(@globals[:services][type].to_sym, @globals[:api_version].to_sym)
    end

    def report(definition)
      @api.report_utils.download_report(definition)
    end
  end
end
