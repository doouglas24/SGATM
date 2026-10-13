package com.sgatm_db.aplicacao.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "equipamento")
public class Equipamento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String tipo;      // Ex: Notebook, Smartphone, Impressora
    private String modelo;    // Ex: Lenovo ThinkPad X13, Poco X6 Pro
    private String descricaoDefeito;

    @ManyToOne
    private Cliente cliente;  // Relação: Muitos equipamentos pertencem a um cliente

    // Construtores
    public Equipamento() {}

    // Getters e Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }

    public String getModelo() { return modelo; }
    public void setModelo(String modelo) { this.modelo = modelo; }

    public String getDescricaoDefeito() { return descricaoDefeito; }
    public void setDescricaoDefeito(String descricaoDefeito) { this.descricaoDefeito = descricaoDefeito; }

    public Cliente getCliente() { return cliente; }
    public void setCliente(Cliente cliente) { this.cliente = cliente; }
}