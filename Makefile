.PHONY: build up down restart logs db-create db-migrate db-setup db-reset test console bash

build:
	docker compose build

up:
	docker compose up

up-d:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart app

logs:
	docker compose logs -f app

db-create:
	docker compose run --rm app bin/rails db:create
	docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgresql://shipment_tracker:password@db:5432/shipment_tracker_test app bin/rails db:create

db-migrate:
	docker compose run --rm app bin/rails db:migrate
	docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgresql://shipment_tracker:password@db:5432/shipment_tracker_test app bin/rails db:migrate

db-setup: db-create db-migrate

db-reset:
	docker compose run --rm app bin/rails db:drop db:create db:migrate
	docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgresql://shipment_tracker:password@db:5432/shipment_tracker_test app bin/rails db:drop db:create db:migrate

test:
	docker compose run --rm \
		-e RAILS_ENV=test \
		-e DATABASE_URL=postgresql://shipment_tracker:password@db:5432/shipment_tracker_test \
		app bundle exec rspec

console:
	docker compose run --rm app bin/rails console

bash:
	docker compose run --rm app sh

routes:
	docker compose run --rm app bin/rails routes
