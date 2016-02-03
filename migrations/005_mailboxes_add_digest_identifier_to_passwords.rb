Sequel.migration do
  up do
    puts <<-MESSAGE

    WARNING ---------------------------------------------------------------------------------

    You need to adapt your mailserver configuration with this version of smailr, as
    passwords are now stored including the hash scheme.

    Select the hash from `mailboxes.password` and the scheme from `mailboxes.password_scheme`

    --------------------------------------------------------------------------------- WARNING

    MESSAGE

    add_column :mailboxes, :password_scheme, String

    from(:mailboxes).update(password_scheme: "{SHA}")

    alter_table(:mailboxes) do
      set_column_not_null(:password_scheme)
    end
  end

  # Downgrade is not supported, as we would drop necessary information do do effective hashing
  # in case this feature was already used to add various hashes to the database
end
