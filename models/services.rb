module RockMultiagent
    data_service_type 'FIPAMessageProviderSrv' do
        output_port 'fipa_out', '/fipa/SerializedLetter'
    end

    data_service_type 'FIPAMessageConsumerSrv' do
        input_port 'fipa_in', '/fipa/SerializedLetter'
    end
end
