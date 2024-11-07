# frozen_string_literal: true

class Service::Form
  include FormObject

  attribute :name
  attribute :image

  attribute :resources do
    attribute :cpu_request, default: 1
    attribute :cpu_limit, default: 2
    attribute :memory_request, default: 1
    attribute :memory_limit, default: 2

    attribute :cpu_request_unit, default: "Cores"
    attribute :cpu_limit_unit, default: "Cores"
    attribute :memory_request_unit, default: "Gi"
    attribute :memory_limit_unit, default: "Gi"

    validates :cpu_request, presence: true, numericality: { greater_than: 0, less_than: 10000 }
    validates :cpu_limit, presence: true, numericality: { greater_than: 0, less_than: 10000 }
    validates :memory_request, presence: true, numericality: { greater_than: 0, less_than: 10000 }
    validates :memory_limit, presence: true, numericality: { greater_than: 0, less_than: 10000 }

    validates :cpu_request_unit, presence: true, inclusion: { in: %w[Cores mCores] }
    validates :cpu_limit_unit, presence: true, inclusion: { in: %w[Cores mCores] }
    validates :memory_request_unit, presence: true, inclusion: { in: %w[Gi Mi Ki] }
    validates :memory_limit_unit, presence: true, inclusion: { in: %w[Gi Mi Ki] }
    validate :cpu_limit_less_than_cpu_request
    validate :memory_limit_less_than_memory_request

    def cpu_limit_less_than_cpu_request
      cpu_request_total = cpu_request.to_i * (cpu_request_unit == "Cores" ? 1000 : 1)
      cpu_limit_total = cpu_limit.to_i * (cpu_limit_unit == "Cores" ? 1000 : 1)
      return if cpu_limit_total >= cpu_request_total

      errors.add(:cpu_limit, "must be greater than or equal to CPU request")
    end

    def memory_limit_less_than_memory_request
      memory_request_total = memory_request.to_i * (memory_request_unit == "Gi" ? 1024**2 : memory_request_unit == "Mi" ? 1024**1 : 1)
      memory_limit_total = memory_limit.to_i * (memory_limit_unit == "Gi" ? 1024**2 : memory_limit_unit == "Mi" ? 1024**1 : 1)
      return if memory_limit_total >= memory_request_total

      errors.add(:memory_limit, "must be greater than or equal to memory request")
    end
  end

  attribute :environment_variables, multiple: true do
    attribute :templated, default: false
    attribute :name
    attribute :value

    validate :name_valid

    def name_valid
      # for now allow empty names which we will ignore when creating the service object
      return if name.blank?
      return if name.match?(/^[a-zA-Z_][a-zA-Z0-9_]*$/)

      errors.add(:name, "must start with a letter or underscore and contain only letters, numbers, and underscores")
    end
  end

  attribute :secrets, multiple: true do
    attribute :name

    validates :name, length: { maximum: 253 } # restrict to 253 characters to match kubernetes secret name limit
    validate :name_valid

    def name_valid
      return if name.blank?
      return if name.match?(/\A[a-z0-9][a-z0-9.-]*[a-z0-9]\z/)

      errors.add(:name, "must start and end with a letter or number and contain only letters, numbers, periods, and hyphens")
    end
  end

  validates :name, presence: true
  validates :image, presence: true
  validate :image_format
  validate :name_format

  def build_service
    ProjectService.new(**service_params)
  end

  def create_service(project_version)
    project_version.project_services.create!(**service_params)
  end

  def update_service(service)
    service.update!(**service_params)
  end

  private

  def service_params
    {
      name:,
      image:,
      resources: resources_object,
      environment_variables: environment_variables_object,
      secrets: secrets_object
    }
  end

  def resources_object
    {
      cpu_request_combined: "#{resources.cpu_request}#{resources.cpu_request_unit}",
      cpu_limit_combined: "#{resources.cpu_limit}#{resources.cpu_limit_unit}",
      memory_request_combined: "#{resources.memory_request}#{resources.memory_request_unit}",
      memory_limit_combined: "#{resources.memory_limit}#{resources.memory_limit_unit}",
      cpu_request: resources.cpu_request,
      cpu_limit: resources.cpu_limit,
      memory_request: resources.memory_request,
      memory_limit: resources.memory_limit,
      cpu_request_unit: resources.cpu_request_unit,
      cpu_limit_unit: resources.cpu_limit_unit,
      memory_request_unit: resources.memory_request_unit,
      memory_limit_unit: resources.memory_limit_unit
    }
  end

  def environment_variables_object
    # filter out empty environment variables names
    # TODO: we should handle this client side more gracefully..
    environment_variables.select { |env| env.name.present? }.map do |env|
      { name: env.name, value: env.value, templated: env.templated }
    end
  end

  def secrets_object
    secrets.select { |secret| secret.name.present? }.map(&:name)
  end

  def name_format
    # name should be lower case and contain only letters, numbers, and hyphens and no spaces
    return if name.match?(/\A[a-z0-9-]+\z/)

    errors.add(:name, "must be lower case and contain only letters, numbers, and hyphens")
  end

  def image_format
    begin
      url = DockerImageUrlParser.new(image)
    rescue DockerImageUrlParser::InvalidDockerImageURLError
      return errors.add(:image, "is not a valid docker image")
    end
    return if url.tag != "latest"

    errors.add(:image, "must specify an image version and not latest")
  end
end
