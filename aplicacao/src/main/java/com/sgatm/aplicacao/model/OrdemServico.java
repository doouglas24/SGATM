package com.sgatm_db.aplicacao.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "ordem_servico")
public class OrdemServico {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String descricaoServico;
    private Double valor;
    private String status; // Ex: Aberta, Em Andamento, Concluída, Cancelada

    @ManyToOne
    private Cliente cliente;

    @ManyToOne
    private Equipamento equipamento;

    // Construtores
    public OrdemServico() {}

    // Getters e Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getDescricaoServico() { return descricaoServico; }
    public void setDescricaoServico(String descricaoServico) { this.descricaoServico = descricaoServico; }

    public Double getValor() { return valor; }
    public void setValor(Double valor) { this.valor = valor; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Cliente getCliente() { return cliente; }
    public void setCliente(Cliente cliente) { this.cliente = cliente; }

    public Equipamento getEquipamento() { return equipamento; }
    public void setEquipamento(Equipamento equipamento) { this.equipamento = equipamento; }
}