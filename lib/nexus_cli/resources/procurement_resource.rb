module NexusCli
  class ProcurementResource < NexusCli::Resource

    # Starts procurement on the provided repository. The given repository
    # becomes a procurement repository, and the procured_from_repository
    # is the repository that acts as the source of artifacts.
    #
    # @param  repository [String] the repository to become a procurement repository
    # @param  procured_from_repository [String] the repository whose artifacts will be procured
    # 
    # @return [type] [description]
    def start(repository, procured_from_repository)
      rest_request(:post, "procurement/manage", get_payload(repository, procured_from_repository))
    end

    # Stops procurement on the provided repository. Note that once
    # procurement has been started on a given repository, it may not be in
    # the same state when you stop procurement on it.
    #
    # @param  repository [String] the procurement repository to stop procurement on
    # 
    # @return [type] [description]
    def stop(repository)
      rest_request(:delete, "procurement/manage/#{repository}")
    end

    # Adds a new rule to the procured repository
    #
    # @param  repository [String] the repository to add a rule to
    # @param  rule [NexusCli::RuleObject] a rule object that represents the new rule
    # 
    # @return [type] [description]
    def add_rule(repository, rule)
      rest_request(:post, "procurement/resolutions/#{repository}", rule)
    end

    # Returns an Array of the current rules for the given
    # procurement repository.
    # 
    # @param  repository [String] the id of the repository
    # 
    # @return [Array<RuleOBject>] the applied procurement rules on this repository
    def rules(repository)
      response = rest_request(:get, "procurement/resolutions/#{repository}")
      response.data.collect { |rule| NexusCli::RuleObject.from_nexus_response(rule) }
    end

    private
      def get_payload(repository, procured_from_repository)
        json_payload = {"data" => {"repositoryId" => repository, "targetClassId" => "repositories", "targetId" => procured_from_repository}}
        JSON.dump(json_payload)
      end
  end
end
