Sequel.migration do
    up do
        # Remove this until we figured out whats wrong with error handling
        # and we can do it for all fields
        alter_table(:mailboxes) do
            set_column_allow_null(:password_scheme)
        end
    end

    # Downgrade is not supported, as we would drop necessary information do do effective hashing
    # in case this feature was already used to add various hashes to the database
end
