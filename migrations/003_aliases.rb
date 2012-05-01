Sequel.migration do
    change do
        create_table :aliases do
            primary_key :id
            foreign_key :domain_id
            String :localpart
            String :dstlocalpart
            String :dstdomain
            index [:domain_id, :localpart, :dstlocalpart, :dstdomain], :unique => true
        end
    end
end
