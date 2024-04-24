resource "aws_ecr_repository" "ecr" {
  name = var.image_name
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.ecr.name
 
  policy = jsonencode({
   rules = [{
     rulePriority = 1
     description  = "keep last 10 images"
     action       = {
       type = "expire"
     }
     selection     = {
       tagStatus   = "any"
       countType   = "imageCountMoreThan"
       countNumber = 10
     }
   }]
  })
}