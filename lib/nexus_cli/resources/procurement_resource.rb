module NexusCli
  class ProcurementResource < NexusCli::Resource
    def start(repository, procured_from_repository)
      rest_request(:post, "procurement/manage", get_payload(repository, procured_from_repository))
    end

    private
      def get_payload(repository, procured_from_repository)
        json_payload = {"data" => {"repositoryId" => repository, "targetClassId" => "repositories", "targetId" => procured_from_repository}}
        JSON.dump(json_payload)
      end
  end
end
