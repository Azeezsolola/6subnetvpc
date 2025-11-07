#------------------------------Creating EFS -------------------------------------------
resource "aws_efs_file_system" "efsclixx" {

  tags = {
    Name = "CLiXXEFS"
  }
}

#---------------------------------Creating Mount Target ------------------------------
#------You need atleast 2 mount targets 

resource "aws_efs_mount_target" "alpha" {
  file_system_id = aws_efs_file_system.efsclixx.id
  subnet_id      = aws_subnet.Privateubnet1.id
  security_groups = [ aws_security_group.EFSIngress.id ]

}

resource "aws_efs_mount_target" "alpha2" {
  file_system_id = aws_efs_file_system.efsclixx.id
  subnet_id      = aws_subnet.Privateubnet2.id
  security_groups = [ aws_security_group.EFSIngress.id ]

}