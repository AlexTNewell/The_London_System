resource "aws_launch_template" "dev_launch_template" {
  name                 = "dev-launch-template"
  image_id             = data.aws_ami.amazon_linux_2.id
  instance_type        = "t2.micro"
  key_name             = aws_key_pair.pepperoni_tf_key.key_name

  vpc_security_group_ids = [aws_security_group.webserver_sg.id]
  
  monitoring {
    enabled = true
  }

  lifecycle {
    create_before_destroy = true
  }

  user_data = "${base64encode(data.template_file.user_data.rendered)}"
}

##################### ASG #####################

resource "aws_autoscaling_group" "dev_asg" {
  name                 = "dev_asg"
  vpc_zone_identifier = [aws_subnet.pri_app_az_1.id, aws_subnet.pri_app_az_2.id]
  target_group_arns = [aws_lb_target_group.dev_target_group.arn]
  health_check_type = "ELB"
  enabled_metrics = ["GroupTotalInstances"]
  launch_template {
    id      = aws_launch_template.dev_launch_template.id
  }
  desired_capacity = 2
  min_size             = 1
  max_size             = 4

  lifecycle {
    create_before_destroy = true
  }
}

##################### ASG Notification #####################

resource "aws_autoscaling_notification" "asg_notifications" {
  group_names = [
    aws_autoscaling_group.dev_asg.name,
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.dev_server_updates.arn
}
