Sequel.migration do
    change do
        create_table :dkims do
            primary_key :id
            foreign_key :domain_id
            String  :private_key, :required => true
            String  :public_key,  :required => true
            String  :selector,    :required => true

            index [:domain_id, :selector], :unique => true
        end
    end
end
