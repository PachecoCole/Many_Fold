# frozen_string_literal: true

class RemoveLeadingSeparatorsFromModelFilenames < ActiveRecord::Migration[7.0]
  def up
    Model.all.each do |model|
      model.update! path: model.path&.trim_path_separators
    rescue ActiveRecord::RecordInvalid
      # If the path is invalid as it's already taken, this is a duplicate, so destroy it.
      model.destroy!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
