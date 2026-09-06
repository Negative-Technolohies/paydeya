.PHONY: help setup setup-win submodules backend frontend

help:
	@echo "Paydeya setup targets:"
	@echo "  make setup          full bootstrap (setup.sh)"
	@echo "  make setup-win      full bootstrap, Windows (setup.ps1)"
	@echo "  make submodules     init submodules only"
	@echo "  make backend        backend setup only"
	@echo "  make frontend       frontend only"
	@echo
	@echo "Options via FLAGS, e.g.: make setup FLAGS=\"--latest --ci\""

setup:
	bash setup.sh $(FLAGS)

setup-win:
	powershell -NoProfile -ExecutionPolicy Bypass -File ./setup.ps1 $(FLAGS)

submodules:
	bash setup.sh --no-backend --no-frontend $(FLAGS)

backend:
	bash setup.sh --no-frontend $(FLAGS)

frontend:
	bash setup.sh --no-backend $(FLAGS)