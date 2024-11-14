# frozen_string_literal: true

class Service::Form
  include FormObject

  attribute :service_id
  attribute :name
  attribute :image

  attribute :cpu_cores, default: 1
  attribute :memory_bytes, default: 1.gigabyte

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
      return if name.match?(/^[a-zA-Z_][a-zA-Z0-9_]*$/)

      errors.add(:name, "must start with a letter or underscore and contain only letters, numbers, and underscores")
    end
  end

  validates :name, presence: true
  validates :image, presence: true
  validate :image_format
  validate :name_format
  validate :unique_environment_variable_secret_names

  def self.empty
    f = Service::Form.new
    f.environment_variables.build
    f.secrets.build

    f
  end

  def self.from_service(service)
    f = Service::Form.new
      f.assign_attributes(
        service_id: service.id,
        name: service.name,
        image: service.image,
        cpu_cores: service.cpu_cores,
        memory_bytes: service.memory_bytes,
        environment_variables: service.environment_variables.map do |env|
          { name: env[:name], value: env[:value], templated: env[:templated] }
        end,
        secrets: service.secrets.map { |secret| { name: secret } }
      )

    f
  end

  def build_service
    ProjectService.new(**service_params)
  end

  def create_service(project_version)
    project_version.services.create!(**service_params)
  end

  def update_service(service)
    service.update!(**service_params)
  end

  private

  def service_params
    {
      name:,
      image:,
      cpu_cores: cpu_cores.to_i,
      memory_bytes: memory_bytes.to_i,
      environment_variables: environment_variables_object,
      secrets: secrets_object
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

  def unique_environment_variable_secret_names
    names = environment_variables.map(&:name) + secrets.map(&:name)
    duplicates = names.group_by(&:itself).select { |_, group| group.length > 1 }.keys

    return if duplicates.empty?

    errors.add(
      :environment_variables,
      "and secrets must have unique names. Duplicates found: #{duplicates.join(', ')}"
    )
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
