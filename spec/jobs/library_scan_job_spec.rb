require "rails_helper"
require "support/mock_directory"

RSpec.describe LibraryScanJob do
  before :all do
    ActiveJob::Base.queue_adapter = :test
  end

  context "with fixtures" do
    let(:library) do
      create(:library, path: Rails.root.join("spec/fixtures/library"))
    end

    it "can scan a library directory" do
      expect { described_class.perform_now(library) }.to change { library.models.count }.to(4)
      expect(library.models.map(&:name)).to contain_exactly("Model One", "Model Two", "Nested Model", "Thingiverse Model")
      expect(library.models.map(&:path)).to contain_exactly("/model_one", "/subfolder/model_two", "/model_one/nested_model", "/thingiverse_model")
    end

    it "queues up model scans" do
      expect { described_class.perform_now(library) }.to have_enqueued_job(ModelScanJob).exactly(4).times
    end

    it "only scans models with changes on rescan" do
      model_one = create(:model, path: "model_one", library: library)
      ModelScanJob.perform_now(model_one)
      expect { described_class.perform_now(library) }.to have_enqueued_job(ModelScanJob).exactly(3).times
    end

    it "flags models with no files as problems" do
      lib = create(:library, path: File.join("/", "tmp"))
      create(:model, library: lib, path: "missing")
      expect { described_class.perform_now(lib) }.to change(Problem, :count).from(0).to(1)
    end
  end

  context "with various case extensions" do
    around do |ex|
      MockDirectory.create([
        "model/file.stl",
        "model/file.STL",
        "model/file.Stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:disable RSpec/InstanceVariable
    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "detects lowercase file extensions" do
      expect(described_class.new.filenames_on_disk(library)).to include File.join(library.path, "model/file.stl")
    end

    it "detects uppercase file extensions" do
      expect(described_class.new.filenames_on_disk(library)).to include File.join(library.path, "model/file.STL")
    end

    it "detects mixed case file extensions" do
      expect(described_class.new.filenames_on_disk(library)).to include File.join(library.path, "model/file.Stl")
    end
  end
end
