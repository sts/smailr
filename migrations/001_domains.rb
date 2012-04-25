Sequel.migration do
    change do
        create_table :domains do
            primary_key :id
            String :fqdn, :unique => true
        end
    end
end
