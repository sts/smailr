Sequel.migration do
    change do
        create_table :dkims do
            primary_key :id
            foreign_key :domain_id
            String  :private_key, :required => true
            String  :public_key,  :required => true
            String  :mode,        :required => true
            Boolean :testing,     :required => true
        end
    end
end
