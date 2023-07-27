---
layout: k8s
title: 使用client-go操作自定义CRD
date: 2023-07-25 17:18:17
tags: k8s
---

#### 介绍

简洁、高效、无需定义CR相关结构体，实现了四种方法： Get、List、Update、Delete 来操作 CR。

个人觉得这只适合对 CR 字段更改不是很多的环境，如果参数过多可能会有些繁琐。

#### 代码实现

```go
package main

import (
	"context"
	"fmt"
	"path/filepath"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/client-go/dynamic"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/util/homedir"
)

type KubernetesCrdExec interface {
	Get(dynamicClient dynamic.Interface, resource schema.GroupVersionResource, namespace, name string) (*unstructured.Unstructured, error)
	List(dynamicClient dynamic.Interface, resource schema.GroupVersionResource, namespace string) (*unstructured.UnstructuredList, error)
	Update(dynamicClient dynamic.Interface, resource schema.GroupVersionResource, result *unstructured.Unstructured, namespace, name string) (*unstructured.Unstructured, error)
	Delete(dynamicClient dynamic.Interface, resource schema.GroupVersionResource, namespace, name string) error
}

type Alertmanager struct{}

func main() {
	resource := schema.GroupVersionResource{
		Group:    "monitoring.coreos.com",
		Version:  "v1",
		Resource: "alertmanagers", // 这里必须是复数形式
	}

	namespace := "default"
	name := "my-alertmanager"

	dynamicClient, err := getClient()
	if err != nil {
		panic(err.Error())
	}

	var crd KubernetesCrdExec
	crd = Alertmanager{}

	result, err := crd.Get(dynamicClient, resource, namespace, name)
	if err != nil {
		panic(err)
	}

	fmt.Println(result.Object["spec"].(map[string]interface{})["externalUrl"])

	resultLists, err := crd.List(dynamicClient, resource, namespace)
	if err != nil {
		panic(err)
	}

	for _, item := range resultLists.Items {
		name := item.Object["metadata"].(map[string]interface{})["name"]
		namespace := item.Object["metadata"].(map[string]interface{})["namespace"]
		fmt.Printf("%v/%v\n", namespace, name)
	}

	// 在这里对 Object 进行修改，更新字段值。这里相当于更新了 spec.externalUrl = http://127.0.0.1:9093
	result.Object["spec"].(map[string]interface{})["externalUrl"] = "http://127.0.0.1:9093"
	result, err = crd.Update(dynamicClient, resource, result, namespace, name)
	if err != nil {
		panic(err)
	}

	err = crd.Delete(dynamicClient, resource, namespace, name)
	if err != nil {
		panic(err)
	}
}

func (Alertmanager) Get(dynamicClient dynamic.Interface, resource schema.GroupVersionResource, namespace, name string) (*unstructured.Unstructured, error) {
	return dynamicClient.Resource(resource).Namespace(namespace).Get(context.TODO(), name, metav1.GetOptions{})
}

func (Alertmanager) List(dynamicClient dynamic.Interface, resource schema.GroupVersionResource, namespace string) (*unstructured.UnstructuredList, error) {
	return dynamicClient.Resource(resource).Namespace(namespace).List(context.TODO(), metav1.ListOptions{})
}

func (Alertmanager) Update(dynamicClient dynamic.Interface, resource schema.GroupVersionResource, result *unstructured.Unstructured, namespace, name string) (*unstructured.Unstructured, error) {
	return dynamicClient.Resource(resource).Namespace(namespace).Update(context.TODO(), result, metav1.UpdateOptions{})
}

func (Alertmanager) Delete(dynamicClient dynamic.Interface, resource schema.GroupVersionResource, namespace, name string) error {
	return dynamicClient.Resource(resource).Namespace(namespace).Delete(context.TODO(), name, metav1.DeleteOptions{})
}

func getClient() (dynamic.Interface, error) {
	kubeconfig := filepath.Join(homedir.HomeDir(), ".kube", "config")
	config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
	if err != nil {
		return nil, err
	}
	return dynamic.NewForConfig(config)
}
```