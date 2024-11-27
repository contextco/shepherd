# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2024_11_27_122046) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "containers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "deployment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.string "lifecycle_id", null: false
    t.integer "status", default: 0
    t.index ["deployment_id"], name: "index_containers_on_deployment_id"
  end

  create_table "dependencies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "version", null: false
    t.string "repo_url", null: false
    t.uuid "project_version_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "configs", default: {}, null: false
    t.index ["project_version_id"], name: "index_dependencies_on_project_version_id"
  end

  create_table "deployment_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "deployment_id", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deployment_id"], name: "index_deployment_tokens_on_deployment_id"
  end

  create_table "deployments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.index ["team_id"], name: "index_deployments_on_team_id"
  end

  create_table "event_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "container_id", null: false
    t.integer "event_type", default: 0, null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["container_id"], name: "index_event_logs_on_container_id"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "helm_charts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "owner_type", null: false
    t.uuid "owner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_helm_charts_on_owner"
  end

  create_table "helm_repos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "project_subscriber_id", null: false
    t.index ["project_subscriber_id"], name: "index_helm_repos_on_project_subscriber_id"
  end

  create_table "helm_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "helm_repo_id", null: false
    t.index ["helm_repo_id"], name: "index_helm_users_on_helm_repo_id"
  end

  create_table "project_services", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "image"
    t.jsonb "environment_variables", default: {}
    t.jsonb "secrets", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "project_version_id"
    t.float "cpu_cores"
    t.bigint "memory_bytes"
    t.jsonb "ports", default: []
    t.string "predeploy_command"
    t.bigint "pvc_size_bytes"
    t.string "pvc_mount_path"
    t.string "pvc_name"
    t.index ["project_version_id"], name: "index_project_services_on_project_version_id"
  end

  create_table "project_subscribers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "project_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "dummy", default: false, null: false
    t.string "password"
    t.index ["project_id"], name: "index_project_subscribers_on_project_id"
  end

  create_table "project_versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "state", default: 0, null: false
    t.string "version", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "project_id"
    t.index ["project_id"], name: "index_project_versions_on_project_id"
  end

  create_table "projects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.uuid "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_projects_on_team_id"
  end

  create_table "ssh_public_keys", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["user_id"], name: "index_ssh_public_keys_on_user_id"
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "first_name"
    t.string "last_name"
    t.string "profile_picture_url"
    t.uuid "team_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  add_foreign_key "containers", "deployments"
  add_foreign_key "dependencies", "project_versions"
  add_foreign_key "deployment_tokens", "deployments"
  add_foreign_key "deployments", "teams"
  add_foreign_key "event_logs", "containers"
  add_foreign_key "helm_repos", "project_subscribers"
  add_foreign_key "helm_users", "helm_repos"
  add_foreign_key "project_services", "project_versions"
  add_foreign_key "project_subscribers", "projects"
  add_foreign_key "project_versions", "projects"
  add_foreign_key "projects", "teams"
  add_foreign_key "ssh_public_keys", "users"
  add_foreign_key "users", "teams"
end
