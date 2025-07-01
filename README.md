# snowday
Artefatos para apresentação do Snowday - Time SEs Brasil Snowflake


Use database ADMIN;

-- Criar API Integration com Git
create or replace api integration github_api
    api_provider = git_https_api
    api_allowed_prefixes = ('https://github.com/sfc-gh-dpiroto')
    enabled = true
    allowed_authentication_secrets = all


