################################################################################
# Set required providers
################################################################################

provider "aws" {
  alias = "producer"

  profile = "trc-hhagen"

}

provider "aws" {
  alias = "consumer"

  profile = "trc-hhagen-2"
}