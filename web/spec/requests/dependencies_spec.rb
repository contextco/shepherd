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
      configs_attributes: {
        cpu_cores: Dependencies::PostgresqlForm::CPU_CORES_OPTIONS.sample.to_s,
        memory_bytes: Dependencies::PostgresqlForm::MEMORY_OPTIONS.sample.to_s,
        disk_bytes: Dependencies::PostgresqlForm::DISK_OPTIONS.sample.to_s,
        app_version: dependency_object.variants.first.version
      }
    } } }

    it "creates a new dependency" do
      expect { subject }.to change { version.reload.dependencies.count }.by(1)
    end

    it 'adds app_version to configs' do
      subject
      expect(version.dependencies.last.configs['app_version']).to eq(dependency_object.variants.first.version)
    end

    it "redirects to the version page" do
      subject
      expect(response).to redirect_to(version_path(version))
    end

    it 'creates a password' do
      subject
      expect(version.dependencies.last.configs['db_password']).to be_present
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
            configs_attributes: {
              cpu_cores: Dependencies::PostgresqlForm::CPU_CORES_OPTIONS.sample.to_s,
              memory_bytes: Dependencies::PostgresqlForm::MEMORY_OPTIONS.sample.to_s,
              disk_bytes: Dependencies::PostgresqlForm::DISK_OPTIONS.sample.to_s,
              app_version: dependency_object.variants.first.version
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
    context 'with a redis dependency' do
      let(:dependency) { create(:dependency, project_version: version, name: 'redis') }

      subject { patch dependency_path(dependency), params: { dependency: {
        name: 'redis',
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
        expect(dependency.repo_url).to eq('oci://registry-1.docker.io')
        expect(dependency.chart_name).to eq('bitnamicharts/redis')
        expect(dependency.configs['max_memory_policy']).to eq('allkeys-lfu')
        expect(dependency.configs['cpu_cores']).to eq(2)
        expect(dependency.configs['memory_bytes']).to eq(2.gigabyte)
        expect(dependency.configs['disk_bytes']).to eq(20.gigabytes)
      end

      it 'does not update the password' do
        subject
        expect(dependency.reload.configs['db_password']).to eq('password')
      end

      it "redirects to the version page" do
        subject
        expect(response).to redirect_to(version_path(version))
      end

      context 'when using an invalid cpu_cores' do
        subject { patch dependency_path(dependency), params: { dependency: {
          name: 'redis',
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

    context 'with a postgresql dependency' do
      let(:dependency) { create(
        :dependency,
        project_version: version,
        name: 'postgresql',
        version: '16.x.x',
        repo_url: 'oci://registry-1.docker.io',
        chart_name: 'bitnamicharts/postgresql',
        configs: { cpu_cores: 4, disk_bytes: 5368709120, memory_bytes: 4294967296, app_version: '15.x.x', db_name: 'bob', db_user: 'bob_2', db_password: 'password' }
      ) }

      subject { patch dependency_path(dependency), params: { dependency: {
        name: 'postgresql',
        configs_attributes: {
          cpu_cores: 2,
          memory_bytes: 2.gigabyte,
          disk_bytes: 20.gigabytes,
          db_name: 'alice',
          db_user: 'alice_2',
          app_version: '16.x.x'
        }
      } } }

      it 'returns http redirect' do
        subject
        expect(response).to have_http_status(:redirect)
      end

      it "updates the dependency" do
        subject
        expect(dependency.reload.name).to eq('postgresql')
        expect(dependency.version).to eq('16.x.x')
        expect(dependency.repo_url).to eq('oci://registry-1.docker.io')
        expect(dependency.chart_name).to eq('bitnamicharts/postgresql')
        expect(dependency.configs['cpu_cores']).to eq(2)
        expect(dependency.configs['memory_bytes']).to eq(2.gigabyte)
        expect(dependency.configs['disk_bytes']).to eq(20.gigabytes)
        expect(dependency.configs['db_name']).to eq('alice')
        expect(dependency.configs['db_user']).to eq('alice_2')
        expect(dependency.configs['app_version']).to eq('16.x.x')
      end

      it 'does not update config password' do
        subject
        expect(dependency.reload.configs['db_password']).to eq('password')
      end

      it "redirects to the version page" do
        subject
        expect(response).to redirect_to(version_path(version))
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
