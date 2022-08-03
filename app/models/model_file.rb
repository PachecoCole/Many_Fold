class ModelFile < ApplicationRecord
  extend Memoist

  belongs_to :model
  has_many :problems, as: :problematic, dependent: :destroy

  validates :filename, presence: true, uniqueness: {scope: :model}

  default_scope { order(:filename) }

  acts_as_favoritable

  def extension
    File.extname(filename).delete(".").downcase
  end

  def is_image?
    SupportedMimeTypes.image_extensions.include? extension
  end

  def name
    File.basename(filename, ".*").humanize.titleize
  end

  def pathname
    File.join(model.library.path, model.path, filename)
  end

  def calculate_digest
    Digest::SHA512.new.file(pathname).hexdigest
  rescue Errno::ENOENT
    nil
  end

  def bounding_box
    return nil unless mesh
    bbox = Mittsu::Box3.new.set_from_object(mesh)
    bbox.size.to_a
  end

  def duplicates
    ModelFile.where(digest: digest).where.not(id: id)
  end

  def duplicate?
    duplicates.count > 0
  end

  # Used for ETag in conditional GETs
  # See https://guides.rubyonrails.org/caching_with_rails.html#conditional-get-support
  def cache_key_with_version
    digest
  end

  def delete_from_disk_and_destroy
    # Delete actual file
    FileUtils.rm(pathname) if File.exist?(pathname)
    # Rescan any duplicates
    duplicates.each { |x| Scan::AnalyseModelFileJob.perform_later(x) }
    # Remove the db record
    destroy
  end

  private

  def mesh
    loader&.new&.load(pathname)
  end
  memoize :mesh

  def loader
    case extension
    when "obj"
      Mittsu::OBJLoader
    end
  end
end
