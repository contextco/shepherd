# frozen_string_literal: true

class Service::Form
  include FormObject

  MOUNT_DISK_OPTIONS = [
    10.gigabytes, 20.gigabytes, 40.gigabytes, 80.gigabytes, 160.gigabytes, 320.gigabytes
  ].freeze

  attribute :service_id
  attribute :name

  attribute :image
  attribute :image_username
  attribute :image_password

  attribute :cpu_cores, default: 1
  attribute :memory_bytes, default: 1.gigabyte

  attribute :predeploy_command

  attribute :pvc_size_bytes, :integer
  attribute :pvc_mount_path

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

  attribute :ports, multiple: true do
    attribute :port
    attribute :ingress, :boolean, default: false

    validates :port, numericality: { greater_than: 0, less_than: 65536 }, allow_blank: true
  end

  validates :name, presence: true
  validates :image, presence: true
  validates :pvc_size_bytes, inclusion: { in: MOUNT_DISK_OPTIONS }, allow_nil: true
  validates :pvc_mount_path, presence: true, format: { with: %r{\/(?!\/$)(?!\/+)[\w.-]+(?:\/[\w.-]+)*\/?} }, if: -> { pvc_size_bytes.present? }
  validate :image_format
  validate :name_format
  validate :unique_environment_variable_secret_names
  validate :unique_port_numbers
  validate :one_or_none_ingress_ports

  def self.empty
    f = Service::Form.new
    f.environment_variables.build
    f.secrets.build
    f.ports.build

    f
  end

  def self.from_service(service)
    f = Service::Form.new
    f.assign_attributes(
      service_id: service.id,
      name: service.name,
      image: service.image,
      image_username: service.image_username,
      image_password: service.image_password,
      cpu_cores: service.cpu_cores,
      memory_bytes: service.memory_bytes,
      predeploy_command: service.predeploy_command,
      pvc_size_bytes: service.pvc_size_bytes,
      pvc_mount_path: service.pvc_mount_path,
      environment_variables: service.environment_variables.map do |env|
        { name: env[:name], value: env[:value], templated: env[:templated] }
      end,
      secrets: service.secrets.map { |secret| { name: secret.environment_key } },
      ports: service.ports.map { |port| { port: port.to_i, ingress: port.to_i == service.ingress_port } }
    )

    f
  end

  def validate_image
    credentials = image_password.present? ? { username: image_username, password: image_password } : nil

    DockerImage::ImageValidator.new(image, credentials).valid_image?
  end

  def build_service
    ProjectService.new(**service_params.merge(id: service_id))
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
      image_username: image_username.presence,
      image_password: image_password.presence,
      cpu_cores: cpu_cores.to_i,
      memory_bytes: memory_bytes.to_i,
      predeploy_command: predeploy_command.presence,
      pvc_size_bytes: pvc_size_bytes&.to_i,
      pvc_mount_path: pvc_mount_path.presence,
      environment_variables: environment_variables_object,
      secrets: secrets_object,
      ports: ports_object,
      ingress_port: ports.find { |port| port.ingress }&.port&.to_i
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

  def ports_object
    ports.map(&:port).reject(&:empty?).map(&:to_i)
  end

  def unique_environment_variable_secret_names
    names = environment_variables.map(&:name) + secrets.map(&:name)
    duplicates = names.group_by(&:itself).select { |_, group| group.length > 1 }.keys.reject(&:empty?)

    return if duplicates.empty?

    errors.add(
      :environment_variables,
      "and secrets must have unique names. Duplicates found: #{duplicates.join(', ')}"
    )
  end

  def unique_port_numbers
    present_ports = ports.map(&:port).reject(&:empty?)
    return if present_ports.uniq.length == present_ports.length

    errors.add(:ports, "must have unique port numbers")
  end

  def one_or_none_ingress_ports
    return if ports.select(&:ingress).size <= 1

    errors.add(:ports, "must have at most one ingress port")
  end

  def name_format
    # name should be lower case and contain only letters, numbers, and hyphens and no spaces
    return if name.match?(/\A[a-z0-9-]+\z/)

    errors.add(:name, "must be lower case and contain only letters, numbers, and hyphens")
  end

  def image_format
    begin
      url = DockerImage::UrlParser.new(image)
    rescue DockerImage::UrlParser::InvalidDockerImageURLError
      return errors.add(:image, "is not a valid docker image")
    end
    return if url.tag.present?

    errors.add(:image, "must specify an image version and not latest")
  end
end
