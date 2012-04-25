Sequel.migration do
    change do
        create_table :mailboxes do
            primary_key :id
            foreign_key :domain_id
            String :localpart, :required => true
            String :password,  :required => true

            index [:domain_id, :localpart], :unique => true
        end
    end
end
