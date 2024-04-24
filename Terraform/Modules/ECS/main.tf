resource "aws_ecs_cluster" "cluster" {
  name = "${var.env_full_name}-ecs-cluster"
}
