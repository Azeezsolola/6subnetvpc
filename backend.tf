terraform {
  backend "s3" {
    bucket         = "mybucketazeezmain" 
    key            = "terraform.tfstate"            
    region         = "us-east-1"                     
    dynamodb_table = "Forstatefiles"              
    encrypt        = true                            
  }
}
