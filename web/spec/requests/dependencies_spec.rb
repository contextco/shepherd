require 'rails_helper'

RSpec.describe "Dependencies", type: :request do
  let(:user) { create(:user) }
  let(:version) { create(:project_version, team: user.team) }

  before { login_as user }

  describe "GET /index" do
    subject { get version_dependencies_path(version) }

    it "returns http success" do
      subject
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    subject { get new_version_dependency_path(version, name: 'redis') }

    it "returns http success" do
      subject
      expect(response).to have_http_status(:success)
    end

    it "assigns the dependency info" do
      subject
      expect(assigns(:dependency_info)).to be_a(Chart::Dependency)
      expect(assigns(:dependency_info).name).to eq('redis')
    end

    it "assigns a new dependency instance" do
      subject
      expect(assigns(:dependency_instance)).to be_a(Dependencies::RedisForm)
    end
  end

  describe "GET /edit" do
    let(:dependency) { create(:dependency, project_version: version, name: 'redis') }

    subject { get edit_dependency_path(dependency) }

    it "returns http success" do
      subject
      expect(response).to have_http_status(:success)
    end

    it "assigns the dependency info" do
      subject
      expect(assigns(:dependency_info)).to be_a(Chart::Dependency)
      expect(assigns(:dependency_info).name).to eq(dependency.name)
    end

    it "assigns the dependency instance" do
      subject
      expect(assigns(:dependency_instance)).to be_a(Dependencies::RedisForm)
    end
  end

  describe "POST /create" do
    let(:dependency_object) { Chart::Dependency.from_name!('postgresql') }

    subject { post version_dependencies_path(version), params: { dependency: {
      name: dependency_object.name,
      version: dependency_object.variants.sample.version,
      repo_url: dependency_object.repository,
      configs_attributes: {
        cpu_cores: Dependencies::PostgresqlForm::CPU_CORES_OPTIONS.sample.to_s,
        memory_bytes: Dependencies::PostgresqlForm::MEMORY_OPTIONS.sample.to_s,
        disk_bytes: Dependencies::PostgresqlForm::DISK_OPTIONS.sample.to_s
      }
    } } }

    it "creates a new dependency" do
      expect { subject }.to change { version.reload.dependencies.count }.by(1)
    end

    it "redirects to the version page" do
      subject
      expect(response).to redirect_to(version_path(version))
    end

    context 'when using an illegal name' do
      subject { post version_dependencies_path(version), params: { dependency: {
        name: 'Test',
        version: dependency_object.variants.sample.version,
        repo_url: dependency_object.repository
      } } }

      it 'returns an error' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when using an illegal version' do
      subject { post version_dependencies_path(version), params: { dependency: {
        name: dependency_object.name,
        version: '1.0.0',
        repo_url: dependency_object.repository
      } } }

      it 'returns an error' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when using an illegal repo_url' do
      subject { post version_dependencies_path(version), params: { dependency: {
        name: dependency_object.name,
        version: dependency_object.variants.sample.version,
        repo_url: 'http://example.com'
      } } }

      it 'returns an error' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when adding multiple dependencies of the same name' do
      subject do
        2.times do
          post version_dependencies_path(version), params: { dependency: {
            name: dependency_object.name,
            version: dependency_object.variants.sample.version,
            repo_url: dependency_object.repository,
            configs_attributes: {
              cpu_cores: Dependencies::PostgresqlForm::CPU_CORES_OPTIONS.sample.to_s,
              memory_bytes: Dependencies::PostgresqlForm::MEMORY_OPTIONS.sample.to_s,
              disk_bytes: Dependencies::PostgresqlForm::DISK_OPTIONS.sample.to_s
            }
          } }
        end
      end

      it 'only creates 1 dependency' do
        expect { subject }.to change(version.dependencies, :count).by(1)
      end
    end
  end

  describe "PATCH /update" do
    let(:dependency) { create(:dependency, project_version: version) }

    subject { patch dependency_path(dependency), params: { dependency: {
      name: 'redis',
      version: '20.x.x',
      repo_url: 'oci://registry-1.docker.io/bitnamicharts/redis',
      configs_attributes: {
        max_memory_policy: 'allkeys-lfu',
        cpu_cores: 2,
        memory_bytes: 2.gigabyte,
        disk_bytes: 20.gigabytes
      }
    } } }

    it 'returns http redirect' do
      subject
      expect(response).to have_http_status(:redirect)
    end

    it "updates the dependency" do
      subject
      expect(dependency.reload.name).to eq('redis')
      expect(dependency.version).to eq('20.x.x')
      expect(dependency.repo_url).to eq('oci://registry-1.docker.io/bitnamicharts/redis')
      expect(dependency.configs['max_memory_policy']).to eq('allkeys-lfu')
      expect(dependency.configs['cpu_cores']).to eq(2)
      expect(dependency.configs['memory_bytes']).to eq(2.gigabyte)
      expect(dependency.configs['disk_bytes']).to eq(20.gigabytes)
    end

    it "redirects to the version page" do
      subject
      expect(response).to redirect_to(version_path(version))
    end

    context 'when using an invalid cpu_cores' do
      subject { patch dependency_path(dependency), params: { dependency: {
        name: 'redis',
        version: '20.x.x',
        repo_url: 'oci://registry-1.docker.io/bitnamicharts/redis',
        configs_attributes: {
          max_memory_policy: 'allkeys-lfu',
          cpu_cores: 3,
          memory_bytes: 2.gigabyte,
          disk_bytes: 20.gigabytes
        }
      } } }

      it 'returns an redirect' do
        subject
        expect(response).to have_http_status(:redirect)
      end

      it 'does not update the dependency' do
        subject
        expect(dependency.reload.configs['cpu_cores']).not_to eq(3)
      end

      it 'sets a flash error' do
        subject
        expect(flash[:error]).to be_present
      end

      it 'redirects to the edit page' do
        subject
        expect(response).to redirect_to(edit_dependency_path(dependency))
      end
    end
  end

  describe "DELETE /destroy" do
    let!(:dependency) { create(:dependency, project_version: version) }

    subject { delete dependency_path(dependency) }

    it "deletes the dependency" do
      expect { subject }.to change { version.reload.dependencies.count }.by(-1)
    end

    it "redirects to the version page" do
      subject
      expect(response).to redirect_to(version_path(version))
    end
  end
end
