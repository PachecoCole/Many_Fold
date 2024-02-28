require "rails_helper"

RSpec.describe "Models" do
  let(:library) do
    create(:library) do |l|
      before do
        build_list(:model, 15, library: l) { |x| x.save! }
      end
    end
  end
  let(:creator) { create(:creator) }

  describe "GET /models?library={id}&page=2" do
    it "returns paginated models" do # rubocop:todo RSpec/MultipleExpectations
      get "/models?library=#{library.id}&page=2"
      expect(response).to have_http_status(:success)
      expect(response.body).to match(/pagination/)
    end
  end

  describe "GET /libraries/1/models/1" do
    it "returns http success" do
      get "/libraries/1/models/1"
      expect(response).to have_http_status(:success)
    end
  end

  describe "Model Update" do
    it "adds tags to a model" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      put "/libraries/#{library.id}/models/#{library.models.first.id}", params: {model: {tag_list: ["a", "b", "c"]}}
      expect(response).to have_http_status(:redirect)
      tags = library.models.first.tag_list
      expect(tags.length).to eq 3
      expect(tags[0]).to eq "a"
      expect(tags[1]).to eq "b"
      expect(tags[2]).to eq "c"
    end

    it "removes tags from a model" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      first = library.models.first
      first.tag_list = "a, b, c"
      first.save

      put "/libraries/#{library.id}/models/#{library.models.first.id}", params: {model: {tag_list: ["a", "b"]}}
      expect(response).to have_http_status(:redirect)
      tags = library.models.first.tag_list
      expect(tags.length).to eq 2
      expect(tags[0]).to eq "a"
      expect(tags[1]).to eq "b"
    end

    it "both adds and removes tags from a model" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      first = library.models.first
      first.tag_list = "a, b, c"
      first.save

      put "/libraries/#{library.id}/models/#{library.models.first.id}", params: {model: {tag_list: ["a", "b", "d"]}}
      expect(response).to have_http_status(:redirect)
      tags = library.models.first.tag_list
      expect(tags.length).to eq 3
      expect(tags[0]).to eq "a"
      expect(tags[1]).to eq "b"
      expect(tags[2]).to eq "d"
    end
  end

  describe "Bulk Edit" do
    it "updates models creator" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      models = library.models.take(2)
      update = {}
      update[models[0].id] = 1
      update[models[1].id] = 1

      patch "/models/update", params: {models: update, creator_id: creator.id}

      expect(response).to have_http_status(:redirect)
      models.each { |model| model.reload }
      expect(models[0].creator_id).to eq creator.id
      expect(models[1].creator_id).to eq creator.id
    end

    update = {}
    it "adds tags to models" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      library.models.take(2).each do |model|
        update[model.id] = 1
      end

      patch "/models/update", params: {models: update, add_tags: ["a", "b", "c"]}

      expect(response).to have_http_status(:redirect)
      library.models.take(2).each do |model|
        expect(model.tag_list).to eq ["a", "b", "c"]
      end
    end

    it "removes tags from models" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
      update = {}
      library.models.take(2).each do |model|
        model.tag_list = "a, b, c"
        model.save
        update[model.id] = 1
      end

      patch "/models/update", params: {models: update, remove_tags: ["a", "b"]}

      expect(response).to have_http_status(:redirect)
      library.models.take(2).each do |model|
        expect(model.tag_list).to eq ["c"]
      end
    end
  end
end
