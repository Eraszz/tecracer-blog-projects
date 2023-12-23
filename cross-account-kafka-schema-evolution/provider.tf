################################################################################
# Set required providers
################################################################################

provider "aws" {
  alias = "producer"

  profile = "xxxxxxxxx"

}

provider "aws" {
  alias = "consumer"

  profile = "xxxxxxxxx"
}