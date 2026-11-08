terraform {
  required_version = "~> 1.13"

  required_providers {
    posthog = {
      source  = "posthog/posthog"
      version = "1.0.28"
    }
  }

  # The state lives in this repository, encrypted with AES-GCM under a key derived from a
  # passphrase that only the owner's SOPS file holds (scripts/tofu.sh). It names flags, insights
  # and dashboards and holds their ids, nothing secret, but a public repository is no place to
  # find out the hard way that a provider started keeping something it should not.
  encryption {
    key_provider "pbkdf2" "state" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.state
    }

    state {
      method   = method.aes_gcm.state
      enforced = true
    }

    plan {
      method   = method.aes_gcm.state
      enforced = true
    }
  }
}
