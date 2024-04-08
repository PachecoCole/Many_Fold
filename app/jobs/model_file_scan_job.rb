class ModelFileScanJob < ApplicationJob
  queue_as :default

  def perform(file_id)
    file = ModelFile.find(file_id)
    return if file.nil?
    # Try to guess if the file is presupported
    if !(
      file.pathname.split(/[[:punct:]]|[[:space:]]/).map(&:downcase) & ModelFile::SUPPORT_KEYWORDS
    ).empty?
      file.update!(presupported: true)
    end
    # Queue up deeper analysis job
    Analysis::AnalyseModelFileJob.perform_later(file.id)
  end
end
