Sequel.migration do
    change do
        create_table :aliases do
            primary_key :id
            foreign_key :mailbox_id
            String :address, :required => true

            index [:address, :mailbox_id], :unique => true
            index :address
        end
    end
end

