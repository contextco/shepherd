# frozen_string_literal: true

class ProjectService < ApplicationRecord
  after_create :set_pvc_name

  delegate :project, to: :project_version
  belongs_to :project_version
  has_one :team, through: :project_version
  has_one :helm_chart, dependent: :destroy, as: :owner
  has_one :helm_repo, through: :project_version

  validates :name, presence: true

  def environment_variables
    super&.map(&:with_indifferent_access)
  end

  def ingress?
    ingress_port.present?
  end

  def k8s_service_names
    return [] if ports.blank?

    ports.map do |port|
      "http://#{project.name}-#{name}-service.#{project.name}.svc.cluster.local:#{port}"
    end
  end

  class Secret
    def initialize(environment_key:)
      @environment_key = environment_key
    end

    attr_reader :environment_key

    def k8s_name
      raise ArgumentError, "Env variable cannot be empty" if environment_key.blank?

      # Convert to lowercase and replace invalid characters
      secret_name = environment_key.to_s.downcase
                            .gsub(/[^a-z0-9.\-]/, "-")  # Replace invalid chars with hyphen
                            .gsub(/[-.]{2,}/, "-")      # Replace multiple dots/hyphens with single hyphen

      # Ensure it starts and ends with alphanumeric
      secret_name = "x#{secret_name}" if secret_name.match?(/^[^a-z0-9]/)
      secret_name = "#{secret_name}x" if secret_name.match?(/[^a-z0-9]$/)

      # Truncate to maximum length while preserving valid ending
      if secret_name.length > 253
        secret_name = secret_name[0...252]
        secret_name = secret_name.sub(/[^a-z0-9]$/, "x")
      end

      secret_name
    end
  end

  def secrets
    super&.map { |secret| Secret.new(environment_key: secret) }
  end

  def image_tag
    DockerImage::UrlParser.new(image).tag
  end

  def image_without_tag
    DockerImage::UrlParser.new(image).to_s(with_tag: false)
  end

  def image_registry_stub
    DockerImage::UrlParser.new(image).registry_stub
  end

  def compare(other)
    Comparisons::Service.compare(self, other)
  end

  private

  def set_pvc_name
    # persistent name for each project version
    update!(pvc_name: "pvc-#{SecureRandom.alphanumeric(6).downcase}") if pvc_name.blank?
  end
end
