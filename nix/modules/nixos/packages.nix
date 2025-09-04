# NixOS-specific package management
# Contains packages specific to NixOS systems
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
      kwok # kwok可以在几秒钟内设置一个由数千个节点组成的集群。该工具包会模拟这些节点的行为，使其表现得像真实的节点一样，因此它的资源消耗非常低，你可以在笔记本电脑上轻松地进行测试和操作。KWOK 的主要使用场景是帮助开发人员和系统管理员在本地环境中进行大规模集群的测试和调试。它可以用于测试应用程序在大型 k8s 集群中的行为，评估集群的性能和稳定性，以及进行容错和扩展性测试。此外，KWOK 还可以用于演示、培训和学习目的，让用户可以快速搭建和操作一个大规模的 k8s 集群。总体而言，KWOK 是一个用于模拟大规模 k8s 集群的工具包，可以在本地环境中进行快速而低资源消耗的测试和操作。
  ];
}
