# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DockerImage::UrlParser do
  describe '#parse' do
    context 'with valid Docker Hub images' do
      it 'parses official images correctly' do
        parser = described_class.new('nginx:latest')
        expect(parser.registry).to be_nil
        expect(parser.image).to eq('nginx')
        expect(parser.tag).to eq('latest')
      end

      it 'parses official images with specific tags' do
        parser = described_class.new('ubuntu:20.04')
        expect(parser.registry).to be_nil
        expect(parser.image).to eq('ubuntu')
        expect(parser.tag).to eq('20.04')
      end

      it 'parses user images correctly' do
        parser = described_class.new('alecbarber/trust-shepherd:stable')
        expect(parser.registry).to be_nil
        expect(parser.image).to eq('alecbarber/trust-shepherd')
        expect(parser.tag).to eq('stable')
      end

      it 'parses organization images correctly' do
        parser = described_class.new('organization/app:1.0.0')
        expect(parser.registry).to be_nil
        expect(parser.image).to eq('organization/app')
        expect(parser.tag).to eq('1.0.0')
      end

      it 'handles multiple slashes in image names' do
        parser = described_class.new('org/team/project:v1')
        expect(parser.registry).to be_nil
        expect(parser.image).to eq('org/team/project')
        expect(parser.tag).to eq('v1')
      end
    end

    context 'with other registries' do
      it 'parses GitHub Container Registry images' do
        parser = described_class.new('ghcr.io/owner/app:latest')
        expect(parser.registry).to eq('ghcr.io')
        expect(parser.image).to eq('owner/app')
        expect(parser.tag).to eq('latest')
      end

      it 'parses Google Container Registry images' do
        parser = described_class.new('gcr.io/project/image:tag')
        expect(parser.registry).to eq('gcr.io')
        expect(parser.image).to eq('project/image')
        expect(parser.tag).to eq('tag')
      end

      it 'parses Quay.io images' do
        parser = described_class.new('quay.io/organization/repo:1.0')
        expect(parser.registry).to eq('quay.io')
        expect(parser.image).to eq('organization/repo')
        expect(parser.tag).to eq('1.0')
      end

      it 'parses GitLab registry images' do
        parser = described_class.new('registry.gitlab.com/group/project:latest')
        expect(parser.registry).to eq('registry.gitlab.com')
        expect(parser.image).to eq('group/project')
        expect(parser.tag).to eq('latest')
      end
    end

    context 'with invalid image names' do
      invalid_images = [
        '',                    # Empty string
        ' ',                   # Whitespace only
        'image:',              # Empty tag
        ':tag',               # Missing image name
        '/image:tag',         # Leading slash
        'image:tag/',         # Trailing slash
        'image::tag',         # Double colon
        'image:tag:extra',    # Multiple tags
        'reg/image:tag/'      # Trailing slash after tag
      ]

      invalid_images.each do |invalid_image|
        it "raises error for invalid image name: '#{invalid_image}'" do
          expect {
            described_class.new(invalid_image).parse
          }.to raise_error(DockerImage::UrlParser::InvalidDockerImageURLError)
        end
      end
    end
  end

  describe '#to_s' do
    context 'with tag' do
      it 'returns full image name with tag' do
        parser = described_class.new('nginx:1.19')
        expect(parser.to_s).to eq('nginx:1.19')
      end

      it 'includes registry when present' do
        parser = described_class.new('ghcr.io/owner/app:latest')
        expect(parser.to_s).to eq('ghcr.io/owner/app:latest')
      end
    end

    context 'without tag' do
      it 'returns image name without tag' do
        parser = described_class.new('nginx:1.19')
        expect(parser.to_s(with_tag: false)).to eq('nginx')
      end

      it 'includes registry but not tag when present' do
        parser = described_class.new('ghcr.io/owner/app:latest')
        expect(parser.to_s(with_tag: false)).to eq('ghcr.io/owner/app')
      end
    end
  end

  describe 'edge cases' do
    it 'handles tags with dots' do
      parser = described_class.new('image:1.2.3')
      expect(parser.tag).to eq('1.2.3')
    end

    it 'handles tags with hyphens' do
      parser = described_class.new('image:tag-name')
      expect(parser.tag).to eq('tag-name')
    end

    it 'handles tags with underscores' do
      parser = described_class.new('image:tag_name')
      expect(parser.tag).to eq('tag_name')
    end

    it 'handles complex image names' do
      parser = described_class.new('registry.gitlab.com/group/subgroup/project/image:1.2.3-alpha.1')
      expect(parser.registry).to eq('registry.gitlab.com')
      expect(parser.image).to eq('group/subgroup/project/image')
      expect(parser.tag).to eq('1.2.3-alpha.1')
    end

    it 'strips whitespace' do
      parser = described_class.new(' nginx:latest ')
      expect(parser.registry).to be_nil
      expect(parser.image).to eq('nginx')
      expect(parser.tag).to eq('latest')
    end
  end
end
